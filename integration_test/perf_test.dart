// Frame-timing profile of the app's main journeys, on a real device.
//
// Run in profile mode (debug timings are meaningless):
//   flutter drive --profile --no-dds \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/perf_test.dart -d DEVICE_ID
//
// Each journey is wrapped in watchPerformance: build/raster times and the
// number of frames over budget land in build/perf/perf_report.json.
import 'dart:async';
import 'dart:convert';

import 'package:calisthenics/core/routing/app_router.dart';
import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/features/achievements/presentation/screens/achievements_screen.dart';
import 'package:calisthenics/features/discover/presentation/screens/discover_search_screen.dart';
import 'package:calisthenics/features/plans/domain/plan_builder.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:calisthenics/features/user/domain/active_plan.dart';
import 'package:calisthenics/features/user/domain/completed_session.dart';
import 'package:calisthenics/features/workout/domain/workout_request.dart';
import 'package:calisthenics/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// A user three weeks into a plan, with history and favourites.
Map<String, Object> _fullUser() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final plan = ActivePlan(
    templateId: 'foundation-full-body',
    startDate: today.subtract(const Duration(days: 16)),
    profile: const UserProfile(daysPerWeek: 4, sessionMinutes: 20),
  );
  return {
    'onboarding_completed': true,
    'onboarding_schema_version': 3,
    'onboarding_name': 'Samantha',
    'onboarding_selections': jsonEncode(_answers),
    'user_plans': jsonEncode([plan.toJson()]),
    'user_current_plan': 'foundation-full-body',
    'user_history': jsonEncode([
      for (var i = 1; i <= 30; i++)
        CompletedSession(
          finishedAt: today
              .subtract(Duration(days: i))
              .add(const Duration(hours: 8)),
          templateId: 'foundation-full-body',
          sessionName: 'Full Body Foundations · Day $i',
          durationSeconds: 900 + i * 30,
          exerciseNumbers: [for (var n = 1; n <= 6; n++) (i * 6 + n) % 80 + 1],
          efforts: {1: Effort.easy, 2: Effort.hard},
        ).toJson(),
    ]),
    'user_favorites': ['1', '2', '5', '12', '30'],
    'user_records': jsonEncode({'plankSeconds': 95}),
  };
}

/// Someone just starting onboarding.
Map<String, Object> _newUser() => {
  'onboarding_schema_version': 3,
  'onboarding_index': 0,
};

const _workout = WorkoutRequest(
  templateId: 'foundation-full-body',
  progressKey: 'perf|workout',
  session: BuiltSession(
    name: 'Full Body Foundations',
    warmUp: [90, 91],
    items: [
      BuiltItem(exerciseNumber: 1, sets: 2, holdSeconds: 30),
      BuiltItem(exerciseNumber: 2, sets: 2, holdSeconds: 30),
    ],
    coolDown: [95],
    estimatedMinutes: 15,
  ),
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Real frames at the display's pace, as a user sees them.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  /// Lets the app run for [ms], pumping real frames.
  Future<void> run(WidgetTester t, int ms) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 16));
    }
  }

  Finder vertical() => find.byWidgetPredicate(
    (w) =>
        w is Scrollable &&
        (w.axisDirection == AxisDirection.down ||
            w.axisDirection == AxisDirection.up),
  );

  /// Flings the main vertical list down, then back up.
  Future<void> scrollDownUp(WidgetTester t, {int times = 3}) async {
    final list = vertical().hitTestable().first;
    for (var i = 0; i < times; i++) {
      await t.fling(list, const Offset(0, -600), 2500);
      await run(t, 900);
    }
    for (var i = 0; i < times; i++) {
      await t.fling(list, const Offset(0, 600), 2500);
      await run(t, 900);
    }
  }

  Future<void> tapLabel(WidgetTester t, String label) async {
    await t.tap(
      find.bySemanticsLabel(RegExp('^${RegExp.escape(label)}')).first,
    );
  }

  Future<ProviderContainer> launch(
    WidgetTester t,
    Map<String, Object> prefs,
  ) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
    );
    await t.pumpWidget(
      UncontrolledProviderScope(container: c, child: const CalestheticsApp()),
    );
    return c;
  }

  testWidgets('main journeys', (t) async {
    late ProviderContainer c;

    await binding.watchPerformance(() async {
      c = await launch(t, _fullUser());
      await run(t, 4500); // splash reveal + first Plan frame
    }, reportKey: '01_launch_splash_to_plan');

    await binding.watchPerformance(
      () => scrollDownUp(t),
      reportKey: '02_plan_tab_scroll',
    );

    await binding.watchPerformance(() async {
      for (var i = 0; i < 3; i++) {
        await tapLabel(t, 'Current plan');
        await run(t, 900);
        await tapLabel(t, 'Current plan');
        await run(t, 900);
      }
    }, reportKey: '03_plan_dropdown_open_close');

    await binding.watchPerformance(() async {
      await tapLabel(t, 'Discover');
      await run(t, 1500);
      await scrollDownUp(t, times: 4);
      // A horizontal carousel.
      final h = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
      );
      if (h.hitTestable().evaluate().isNotEmpty) {
        await t.fling(h.hitTestable().first, const Offset(-500, 0), 2500);
        await run(t, 900);
      }
    }, reportKey: '04_discover_tab_scroll');

    await binding.watchPerformance(() async {
      await tapLabel(t, 'Progress');
      await run(t, 2000); // count-up and chart entrance animations
      await scrollDownUp(t);
    }, reportKey: '05_progress_tab_scroll');

    await binding.watchPerformance(() async {
      await tapLabel(t, 'Profile');
      await run(t, 1500);
      await scrollDownUp(t, times: 2);
    }, reportKey: '06_profile_tab_scroll');

    await binding.watchPerformance(() async {
      await tapLabel(t, 'Appearance: Dark');
      await run(t, 1800); // circular theme reveal
      await tapLabel(t, 'Appearance: Light');
      await run(t, 1800);
    }, reportKey: '07_theme_switch_reveal');

    final router = c.read(appRouterProvider);
    await binding.watchPerformance(() async {
      unawaited(router.push('/day/1'));
      await run(t, 1500);
      await scrollDownUp(t, times: 2);
      router.pop();
      await run(t, 1000);
    }, reportKey: '08_day_overview_open_scroll');

    await binding.watchPerformance(() async {
      unawaited(router.push('/workout', extra: _workout));
      await run(t, 4000); // "first up" countdown
      await tapLabel(t, 'Skip');
      await run(t, 5000); // exercise timer running
      await tapLabel(t, 'Quit workout');
      await run(t, 800);
      await tapLabel(t, 'Quit');
      await run(t, 1500);
    }, reportKey: '09_workout_player');

    await binding.watchPerformance(() async {
      final nav = Navigator.of(t.element(find.byType(Scaffold).first));
      unawaited(
        nav.push(
          MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()),
        ),
      );
      await run(t, 1500);
      await scrollDownUp(t, times: 2);
      nav.pop();
      await run(t, 1000);
    }, reportKey: '10_achievements_scroll');

    await binding.watchPerformance(() async {
      final nav = Navigator.of(t.element(find.byType(Scaffold).first));
      unawaited(
        nav.push(
          MaterialPageRoute<void>(builder: (_) => const DiscoverSearchScreen()),
        ),
      );
      await run(t, 1200);
      await t.enterText(find.byType(EditableText).first, 'push');
      await run(t, 1500);
      await scrollDownUp(t, times: 2);
      nav.pop();
      await run(t, 1000);
    }, reportKey: '11_search_type_scroll');

    // Onboarding: welcome intro, then the first steps.
    await t.pumpWidget(const SizedBox());
    c.dispose();
    await binding.watchPerformance(() async {
      c = await launch(t, _newUser());
      await run(t, 5000);
      await tapLabel(t, 'Start my journey');
      await run(t, 2500);
      // First answer on the age step.
      final options = find.bySemanticsLabel(RegExp('^Portrait'));
      if (options.evaluate().isNotEmpty) {
        await t.tap(options.first);
        await run(t, 2500);
      }
    }, reportKey: '12_onboarding_welcome_and_steps');
  });
}
