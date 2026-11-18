import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:calisthenics/core/routing/app_router.dart';
import 'package:calisthenics/core/splash/animated_splash.dart';
import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/achievements/presentation/screens/achievement_celebration_screen.dart';
import 'package:calisthenics/features/achievements/presentation/screens/achievement_share_screen.dart';
import 'package:calisthenics/features/achievements/presentation/screens/achievements_screen.dart';
import 'package:calisthenics/features/auth/presentation/widgets/auth_modal_sheet.dart';
import 'package:calisthenics/features/calendar/presentation/screens/day_activity_screen.dart';
import 'package:calisthenics/features/calendar/presentation/widgets/add_activity_sheet.dart';
import 'package:calisthenics/features/coach/presentation/screens/coach_screen.dart';
import 'package:calisthenics/features/discover/presentation/screens/discover_search_screen.dart';
import 'package:calisthenics/features/discover/presentation/screens/exercise_list_screen.dart';
import 'package:calisthenics/features/discover/presentation/screens/media_debug_screen.dart';
import 'package:calisthenics/features/discover/presentation/widgets/premium_sheet.dart';
import 'package:calisthenics/features/exercises/data/exercise_catalog.dart';
import 'package:calisthenics/features/onboarding/data/onboarding_flow.dart';
import 'package:calisthenics/features/onboarding/presentation/widgets/account_ready_dialog.dart';
import 'package:calisthenics/features/plan/presentation/screens/plan_option_edit_screen.dart';
import 'package:calisthenics/features/plan/presentation/widgets/day_locked_dialog.dart';
import 'package:calisthenics/features/plan/presentation/widgets/day_rows.dart';
import 'package:calisthenics/features/plan/presentation/widgets/plan_confirm_dialog.dart';
import 'package:calisthenics/features/plan/presentation/widgets/plan_switch_dialog.dart';
import 'package:calisthenics/features/plans/domain/plan_builder.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:calisthenics/features/profile/presentation/providers/profile_providers.dart';
import 'package:calisthenics/features/profile/presentation/widgets/reminder_sheet.dart';
import 'package:calisthenics/features/user/domain/active_plan.dart';
import 'package:calisthenics/features/user/domain/completed_session.dart';
import 'package:calisthenics/features/user/domain/plank_attempt.dart';
import 'package:calisthenics/features/workout/domain/workout_request.dart';
import 'package:calisthenics/features/workout/presentation/widgets/workout_dialogs.dart';
import 'package:calisthenics/main.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every screen, tab, dialog and sheet of the app on phones and tablets of
/// all common sizes, in portrait (and a landscape subset), with normal and
/// large system text. Each screen is also scrolled to the bottom, since an
/// overflow can hide below the fold. Any FlutterError (RenderFlex overflow,
/// unbounded constraints, …) fails the test, tagged with the screen.
///
/// Run with `--dart-define=SHOTS_DIR=<folder>` to also save a PNG of every
/// screen (top and bottom) for visual review.
const _shotsDir = String.fromEnvironment('SHOTS_DIR');

/// Optional comma-separated scene-name prefixes to limit a run to.
const _only = String.fromEnvironment('ONLY');

class _Device {
  const _Device(this.name, this.size, {this.tablet = false});
  final String name;
  final Size size;
  final bool tablet;
  bool get landscape => size.width > size.height;
}

const _phones = [
  _Device('320x568', Size(320, 568)),
  _Device('360x640', Size(360, 640)),
  _Device('375x667', Size(375, 667)),
  _Device('390x844', Size(390, 844)),
  _Device('430x932', Size(430, 932)),
  _Device('412x915', Size(412, 915)),
];
const _tablets = [
  _Device('600x960', Size(600, 960), tablet: true),
  _Device('768x1024', Size(768, 1024), tablet: true),
  _Device('820x1180', Size(820, 1180), tablet: true),
  _Device('1024x1366', Size(1024, 1366), tablet: true),
];
const _landscape = [
  _Device('844x390', Size(844, 390)),
  _Device('1180x820', Size(1180, 820), tablet: true),
];

/// (device, text scale) pairs to check.
final _configs = <(_Device, double)>[
  for (final d in _phones) (d, 1.0),
  for (final d in _phones) (d, 1.3),
  for (final d in _phones)
    if (d.name == '360x640' || d.name == '390x844') (d, 2.0),
  for (final d in _tablets) (d, 1.0),
  for (final d in _landscape) (d, 1.0),
];

/// Configurations whose screenshots are saved.
bool _shoots(_Device d, double scale) =>
    _shotsDir.isNotEmpty &&
    scale == 1.0 &&
    const {'320x568', '390x844', '1024x1366', '1180x820'}.contains(d.name);

const _longName = 'Alexandria Montgomery-Wellington';

const _answers = {
  'main-goal': ['master-calisthenics-skills'],
  'training-space': ['both'],
  'equipment': ['pull-up-bar', 'resistance-band'],
  'areas-to-protect': ['knees'],
  'training-experience': ['some-experience'],
  'days-per-week': ['days-4'],
  'workout-duration': ['20-min'],
  'time-of-day': ['morning'],
  'plan-choice': ['skill-pull-up'],
  'skill-ability': ['dead-hang'],
};

enum _Data { full, empty, onboarding }

/// SharedPreferences for a user with an active plan, history, favorites,
/// plank records and a long name ([_Data.full]); a user who finished
/// onboarding but has nothing yet ([_Data.empty]); or one mid-onboarding.
Map<String, Object> _seed(_Data data, {int onboardingIndex = 0}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  switch (data) {
    case _Data.onboarding:
      return {
        'onboarding_schema_version': 3,
        'onboarding_index': onboardingIndex,
        'onboarding_name': _longName,
        'onboarding_plank_seconds': 34,
        'onboarding_selections': jsonEncode(_answers),
      };
    case _Data.empty:
      return {
        'onboarding_completed': true,
        'onboarding_schema_version': 3,
        'onboarding_name': _longName,
      };
    case _Data.full:
      final plan = ActivePlan(
        templateId: 'foundation-full-body',
        startDate: today.subtract(const Duration(days: 16)),
        profile: const UserProfile(daysPerWeek: 4, sessionMinutes: 20),
      );
      final other = ActivePlan(
        templateId: 'skill-pull-up',
        startDate: today.subtract(const Duration(days: 3)),
        profile: const UserProfile(daysPerWeek: 3),
      );
      final history = [
        for (var i = 1; i <= 16; i++)
          if (i % 3 != 0)
            CompletedSession(
              finishedAt: today
                  .subtract(Duration(days: i))
                  .add(const Duration(hours: 8)),
              templateId: 'foundation-full-body',
              sessionName: 'Full Body Foundations · Day ${17 - i}',
              durationSeconds: 900 + i * 60,
              exerciseNumbers: [
                for (var n = 1; n <= 6; n++) (i * 6 + n) % 80 + 1,
              ],
              efforts: {1: Effort.easy, 2: Effort.hard},
            ),
        CompletedSession(
          finishedAt: today.add(const Duration(hours: 7)),
          templateId: CompletedSession.manualTemplateId,
          sessionName: 'Evening walk around the neighbourhood and stretching',
          durationSeconds: 2700,
          exerciseNumbers: const [],
        ),
      ];
      return {
        'onboarding_completed': true,
        'onboarding_schema_version': 3,
        'onboarding_name': _longName,
        'onboarding_selections': jsonEncode(_answers),
        'user_plans': jsonEncode([plan.toJson(), other.toJson()]),
        'user_current_plan': 'foundation-full-body',
        'user_history': jsonEncode([for (final s in history) s.toJson()]),
        'user_favorites': ['1', '2', '5', '12', '30'],
        'user_records': jsonEncode({'plankSeconds': 95}),
        'user_plank_history': jsonEncode([
          for (var i = 0; i < 6; i++)
            PlankAttempt(
              at: today.subtract(Duration(days: 20 - i * 3)),
              seconds: 30 + i * 13,
            ).toJson(),
        ]),
      };
  }
}

const _planWorkout = WorkoutRequest(
  templateId: 'foundation-full-body',
  progressKey: 'foundation-full-body|2026-10-14',
  session: BuiltSession(
    name: 'Full Body Foundations with a long session name',
    warmUp: [90],
    items: [
      BuiltItem(exerciseNumber: 1, sets: 2, reps: 12),
      BuiltItem(exerciseNumber: 5, sets: 1, holdSeconds: 30, perSide: true),
    ],
    coolDown: [95],
    estimatedMinutes: 20,
  ),
);

/// Context of the top-most page (under the root navigator, above any dialog).
BuildContext _ctx(WidgetTester t) => t.element(find.byType(Scaffold).last);

NavigatorState _nav(WidgetTester t) =>
    t.state<NavigatorState>(find.byType(Navigator).first);

/// Pushes [page]; like [_go], the route's future is deliberately dropped
/// (an arrow body would hand it back to `await s.open(...)`).
void _push(WidgetTester t, Widget page) {
  unawaited(_nav(t).push(MaterialPageRoute<void>(builder: (_) => page)));
}

Future<void> _tapTab(WidgetTester t, String tab) async {
  await t.tap(find.bySemanticsLabel(tab).first);
}

/// A thing to look at: how to reach it from the home shell, the data it
/// needs and whether to scroll it to the bottom.
class _Scene {
  const _Scene(
    this.name,
    this.open, {
    this.data = _Data.full,
    this.scroll = true,
    this.onboardingIndex = 0,
    this.landscape = false,
    this.steps = const [],
  });
  final String name;
  final FutureOr<void> Function(WidgetTester t, ProviderContainer c) open;
  final _Data data;
  final bool scroll;
  final int onboardingIndex;

  /// Part of the landscape subset.
  final bool landscape;

  /// Further states of the same screen, each checked and shot after [open].
  final List<(String, FutureOr<void> Function(WidgetTester t))> steps;
}

void _noop(WidgetTester t, ProviderContainer c) {}

/// Pushes [location]; the returned future only completes on pop, so it is
/// deliberately not awaited.
void _go(ProviderContainer c, String location, [Object? extra]) {
  unawaited(c.read(appRouterProvider).push(location, extra: extra));
}

Future<void> _tapIf(WidgetTester t, Finder f) async {
  if (f.evaluate().isNotEmpty) await t.tap(f.first, warnIfMissed: false);
}

final _scenes = <_Scene>[
  // Shell tabs.
  const _Scene('tab-plan', _noop, landscape: true),
  _Scene('tab-discover', (t, c) => _tapTab(t, 'Discover'), landscape: true),
  _Scene('tab-progress', (t, c) => _tapTab(t, 'Progress'), landscape: true),
  _Scene('tab-profile', (t, c) => _tapTab(t, 'Profile'), landscape: true),
  const _Scene('empty-tab-plan', _noop, data: _Data.empty),
  _Scene(
    'empty-tab-discover',
    (t, c) => _tapTab(t, 'Discover'),
    data: _Data.empty,
  ),
  _Scene(
    'empty-tab-progress',
    (t, c) => _tapTab(t, 'Progress'),
    data: _Data.empty,
  ),
  _Scene(
    'empty-tab-profile',
    (t, c) => _tapTab(t, 'Profile'),
    data: _Data.empty,
  ),
  // Routes.
  for (final r in [
    '/day/0',
    '/day/1',
    '/day/3',
    '/exercise/1',
    '/exercise/40',
    '/plan-settings',
    '/paywall',
    '/plans',
    '/plans/foundation-full-body',
    '/plans/skill-pull-up',
    '/privacy',
    '/terms',
    '/support',
    '/settings',
    '/history',
    '/favorites',
  ])
    _Scene(
      'route${r.replaceAll('/', '-')}',
      (t, c) => _go(c, r),
      landscape: r == '/paywall',
    ),
  for (final r in ['/history', '/favorites', '/plans', '/plan-settings'])
    _Scene(
      'empty-route${r.replaceAll('/', '-')}',
      (t, c) => _go(c, r),
      data: _Data.empty,
    ),
  for (final o in PlanOption.values)
    _Scene(
      'plan-option-${o.name}',
      (t, c) => _push(t, PlanOptionEditScreen(option: o)),
    ),
  _Scene('achievements', (t, c) => _push(t, const AchievementsScreen())),
  _Scene('achievement-celebration', (t, c) {
    final a = c.read(achievementsProvider).firstWhere((a) => a.unlocked);
    _push(t, AchievementCelebrationScreen(achievement: a));
  }, scroll: false),
  _Scene('achievement-share', (t, c) {
    final a = c.read(achievementsProvider).firstWhere((a) => a.unlocked);
    _push(t, AchievementShareScreen(achievement: a));
  }),
  _Scene('day-activity', (t, c) {
    final now = DateTime.now();
    _push(t, DayActivityScreen(day: now.subtract(const Duration(days: 1))));
  }),
  _Scene('day-activity-today', (t, c) {
    _push(t, DayActivityScreen(day: DateTime.now()));
  }),
  _Scene('day-activity-empty', (t, c) {
    _push(t, DayActivityScreen(day: DateTime.now()));
  }, data: _Data.empty),
  _Scene('coach', (t, c) => _push(t, const CoachScreen())),
  _Scene('discover-search', (t, c) => _push(t, const DiscoverSearchScreen())),
  _Scene('ladders', (t, c) => _push(t, const LaddersScreen())),
  _Scene(
    'ladder-push-up',
    (t, c) => _push(
      t,
      const LadderScreen(skillId: 'push-up', title: 'Push-Up ladder'),
    ),
  ),
  _Scene(
    'section',
    (t, c) => _push(
      t,
      SectionScreen(
        title: 'Beginner friendly favourites for every day',
        exercises: exerciseCatalog.take(12).toList(),
      ),
    ),
  ),
  _Scene('media-debug', (t, c) => _push(t, const MediaDebugScreen())),
  // The workout player through its phases.
  _Scene(
    'workout',
    (t, c) => _go(c, '/workout', _planWorkout),
    scroll: false,
    landscape: true,
    steps: [
      ('warmup', (t) => _tapIf(t, find.text('Skip'))),
      ('details', (t) => _tapIf(t, find.byTooltip('Show details'))),
      (
        'first-up',
        (t) async {
          await _tapIf(t, find.byTooltip('Hide details'));
          await t.pump(const Duration(milliseconds: 400));
          await _tapIf(t, find.byTooltip('Next'));
        },
      ),
      ('exercise', (t) => _tapIf(t, find.text('Skip'))),
      (
        'music',
        (t) async {
          final b = find.byTooltip('Music settings');
          if (b.evaluate().isNotEmpty) await t.tap(b.first);
        },
      ),
      (
        'rest-or-effort',
        (t) async {
          Navigator.of(_ctx(t)).maybePop();
          await t.pump(const Duration(milliseconds: 400));
          await t.pump();
          await _tapIf(t, find.byTooltip('Next'));
        },
      ),
      ('quit-dialog', (t) => _tapIf(t, find.byTooltip('Quit workout'))),
      (
        'complete',
        (t) async {
          await _tapIf(t, find.text('Keep going'));
          for (var i = 0; i < 12; i++) {
            if (find.text('WORKOUT COMPLETE').evaluate().isNotEmpty) break;
            await _tapIf(t, find.text('Easy'));
            await _tapIf(t, find.text('Skip'));
            await _tapIf(t, find.byTooltip('Next'));
            await t.pump(const Duration(milliseconds: 400));
            await t.pump();
          }
        },
      ),
    ],
  ),
  _Scene(
    'workout-demo',
    (t, c) => _go(c, '/workout', WorkoutRequest.demo(1, 'Wall Push-Up')),
    scroll: false,
  ),
  // Dialogs and sheets.
  _Scene('dialog-quit', (t, c) {
    unawaited(showQuitDialog(_ctx(t), percent: 50));
  }, scroll: false),
  _Scene('sheet-audio', (t, c) {
    unawaited(showAudioSheet(_ctx(t)));
  }, scroll: false),
  _Scene('sheet-reminder', (t, c) {
    unawaited(showReminderSheet(_ctx(t)));
  }, scroll: false),
  _Scene('sheet-auth', (t, c) {
    unawaited(showAuthModalSheet(_ctx(t)));
  }, scroll: false),
  _Scene('sheet-auth-signup', (t, c) {
    unawaited(showAuthModalSheet(_ctx(t), initialIsSignUp: true));
  }, scroll: false),
  _Scene('sheet-add-activity', (t, c) {
    unawaited(showAddActivity(_ctx(t), day: DateTime.now()));
  }, scroll: false),
  _Scene('sheet-premium', (t, c) {
    unawaited(showPremiumSheet(_ctx(t)));
  }, scroll: false),
  _Scene('sheet-day-rest', (t, c) {
    unawaited(showDayRestSheet(_ctx(t)));
  }, scroll: false),
  _Scene('dialog-day-locked', (t, c) {
    unawaited(
      showDayLockedDialog(
        _ctx(t),
        finishDay: 3,
        tappedDay: 5,
        opensOn: 'Wednesday, September 30',
      ),
    );
  }, scroll: false),
  _Scene('dialog-plan-confirm', (t, c) {
    unawaited(
      showPlanConfirmDialog(
        _ctx(t),
        title: 'Restart Full Body Foundations?',
        message: 'Your plan starts again from day one. Your workout history is kept.',
        detail: 'Half-finished days are cleared.',
        confirmLabel: 'Restart plan',
      ),
    );
  }, scroll: false),
  _Scene('dialog-plan-switch', (t, c) {
    unawaited(
      showSwitchPlanDialog(_ctx(t), planName: 'Pull-Up Skill Mastery Program'),
    );
  }, scroll: false),
  _Scene('dialog-account-ready', (t, c) {
    unawaited(
      showAccountReadyDialog(
        _ctx(t),
        isNew: true,
        email: 'alexandria.montgomery-wellington@example.com',
      ),
    );
  }, scroll: false),
  // Onboarding (every step).
  for (var i = 0; i < onboardingSteps.length; i++)
    _Scene(
      'onboarding-$i-${onboardingSteps[i].id}',
      _noop,
      data: _Data.onboarding,
      onboardingIndex: i,
    ),
];

/// Real fonts, so text measures true (see device_sizes_test.dart).
Future<void> _loadAppFonts() async {
  for (final (family, files) in [
    (
      'Poppins',
      ['Poppins-Regular', 'Poppins-Medium', 'Poppins-SemiBold', 'Poppins-Bold'],
    ),
    ('Lora', ['Lora-Medium']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('assets/google_fonts/$f.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }
  // Icons too, so screenshots show them instead of boxes.
  final root = Platform.environment['FLUTTER_ROOT'];
  final icons = File(
    '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (root != null && icons.existsSync()) {
    final bytes = icons.readAsBytesSync();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  }
}

final _shotKey = GlobalKey();

Future<void> _shot(WidgetTester t, String file, double ratio) async {
  // Give asset images a moment to decode so the picture is complete.
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  await t.pump();
  await t.runAsync(() async {
    final boundary =
        _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: ratio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final f = File('$_shotsDir/$file.png');
    f.parent.createSync(recursive: true);
    f.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Lets a screen's entrance animations finish, a frame every 100 ms.
Future<void> _settle(WidgetTester t, [int frames = 16]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Scrolls every visible vertical scrollable to its end.
Future<bool> _scrollToBottom(WidgetTester t) async {
  var moved = false;
  for (var pass = 0; pass < 4; pass++) {
    var any = false;
    for (final s in t.stateList<ScrollableState>(
      find.byType(Scrollable).hitTestable(),
    )) {
      final p = s.position;
      if (p.axis != Axis.vertical || !p.hasContentDimensions) continue;
      if (p.pixels < p.maxScrollExtent - 0.5) {
        p.jumpTo(p.maxScrollExtent);
        any = moved = true;
      }
    }
    if (!any) break;
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(milliseconds: 300));
  }
  // Rows built by the scroll play their entrance animation first.
  if (moved) await t.pump(const Duration(milliseconds: 1500));
  return moved;
}

void main() {
  setUpAll(_loadAppFonts);

  for (final (device, scale) in _configs) {
    final label = '${device.name} x$scale';
    testWidgets('$label · every screen', (t) async {
      const dpr = 3.0;
      t.view.physicalSize = device.size * dpr;
      t.view.devicePixelRatio = dpr;
      // Phones have a status bar and a home indicator; tablets too.
      t.view.padding = FakeViewPadding(
        top: (device.landscape ? 0 : 47) * dpr,
        bottom: 34 * dpr,
      );
      t.view.viewPadding = t.view.padding;
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final shoot = _shoots(device, scale);
      final ratio = device.tablet ? 1.0 : 1.5;

      final failures = <String>[];
      final previous = FlutterError.onError;
      var scene = '';
      FlutterError.onError = (d) => failures.add(
        '[$scene] ${d.toString().split('\n').take(16).join('\n')}',
      );
      try {
        for (final s in _scenes) {
          if (device.landscape && !s.landscape) continue;
          if (_only.isNotEmpty &&
              !_only.split(',').any((p) => s.name.startsWith(p))) {
            continue;
          }
          scene = s.name;
          // ignore: avoid_print
          print(scene);
          SharedPreferences.setMockInitialValues(
            _seed(s.data, onboardingIndex: s.onboardingIndex),
          );
          final prefs = await SharedPreferences.getInstance();
          final container = ProviderContainer(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          );
          try {
            await t.pumpWidget(
              RepaintBoundary(
                key: _shotKey,
                child: UncontrolledProviderScope(
                  container: container,
                  child: const CalestheticsApp(),
                ),
              ),
            );
            await t.pump(const Duration(milliseconds: 100));
            await t.pump(const Duration(milliseconds: 1500));
            await s.open(t, container);
            await t.pump(); // a new route starts offstage
            await _settle(t);
            final file = '${device.name}/${s.name}';
            if (shoot) await _shot(t, file, ratio);
            if (s.scroll && await _scrollToBottom(t) && shoot) {
              await _shot(t, '$file-bottom', ratio);
            }
            for (final (name, step) in s.steps) {
              scene = '${s.name}/$name';
              await step(t);
              await t.pump();
              await t.pump(const Duration(milliseconds: 100));
              await t.pump(const Duration(milliseconds: 900));
              if (shoot) await _shot(t, '$file-$name', ratio);
            }
          } catch (e, st) {
            failures.add(
              '[$scene] threw $e\n${st.toString().split('\n').take(6).join('\n')}',
            );
          } finally {
            // Tear the tree down so no timer of this scene outlives it.
            await t.pumpWidget(const SizedBox());
            await t.pump(const Duration(seconds: 1));
            container.dispose();
          }
        }
      } finally {
        FlutterError.onError = previous;
      }
      expect(failures, isEmpty, reason: failures.join('\n---\n'));
    });
  }

  // The launch animation, sampled through its run.
  for (final (device, scale) in _configs) {
    testWidgets('${device.name} x$scale · animated splash', (t) async {
      t.view.physicalSize = device.size * 3;
      t.view.devicePixelRatio = 3;
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final errors = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.toString());
      try {
        await t.pumpWidget(
          RepaintBoundary(
            key: _shotKey,
            child: MaterialApp(
              theme: AppTheme.light,
              home: AnimatedSplash(onDone: () {}),
            ),
          ),
        );
        for (var i = 0; i < 8; i++) {
          await t.pump(const Duration(milliseconds: 450));
          if (i == 5 && _shoots(device, scale)) {
            await _shot(t, '${device.name}/splash', device.tablet ? 1.0 : 1.5);
          }
        }
      } finally {
        FlutterError.onError = previous;
      }
      expect(errors, isEmpty, reason: errors.join('\n---\n'));
    });
  }
}
