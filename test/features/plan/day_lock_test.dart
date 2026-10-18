import 'dart:convert';

import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/plan/domain/plan_timeline.dart';
import 'package:calisthenics/features/plan/presentation/screens/plan_screen.dart';
import 'package:calisthenics/features/plans/data/plan_templates.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:calisthenics/features/user/domain/active_plan.dart';
import 'package:calisthenics/features/user/domain/completed_session.dart';
import 'package:calisthenics/features/user/presentation/providers/user_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _template = planTemplates.firstWhere(
  (t) => t.id == 'foundation-full-body',
);
const _profile = UserProfile(daysPerWeek: 3);
// Monday 12 Oct 2026: the plan's first day.
final _start = DateTime(2026, 10, 12);
final _plan = ActivePlan(
  templateId: _template.id,
  startDate: _start,
  profile: _profile,
);

CompletedSession _done(DateTime at) => CompletedSession(
  finishedAt: at,
  templateId: _template.id,
  sessionName: 's',
  durationSeconds: 600,
  exerciseNumbers: const [1],
);

PlanTimeline _timeline(DateTime today, [List<CompletedSession> h = const []]) =>
    PlanTimeline.build(
      template: _template,
      plan: _plan,
      history: h,
      today: today,
    );

void main() {
  group('which days are locked', () {
    test('everything after the day to do now', () {
      final t = _timeline(_start);
      final days = [for (final p in t.phases) ...p.days];
      expect(t.hero!.dayNumber, 1);
      expect(t.isLocked(days[0]), isFalse);
      expect(days.skip(1).every(t.isLocked), isTrue);
    });

    test('finishing a day opens the next one', () {
      final t = _timeline(DateTime(2026, 10, 14), [_done(_start)]);
      final days = [for (final p in t.phases) ...p.days];
      expect(t.hero!.dayNumber, 2);
      expect(t.isLocked(days[0]), isFalse); // done
      expect(t.isLocked(days[1]), isFalse); // the one to do now
      expect(t.isLocked(days[2]), isTrue);
    });

    test('a missed day never blocks the rest of the plan', () {
      // Day 1 (Mon) was missed; today is Wed, day 2 is today's session.
      final t = _timeline(DateTime(2026, 10, 14));
      final days = [for (final p in t.phases) ...p.days];
      expect(days[0].status, TimelineStatus.missed);
      expect(t.hero!.dayNumber, 2);
      expect(t.isLocked(days[0]), isFalse);
      expect(t.isLocked(days[1]), isFalse);
      expect(t.isLocked(days[2]), isTrue);
    });

    test('nothing is locked when the block is finished', () {
      final history = [
        for (var i = 0; i < 12; i++) _done(DateTime(2026, 10, 12 + i)),
      ];
      final t = _timeline(DateTime(2026, 10, 24), history);
      expect(t.hero, isNull);
      expect([for (final p in t.phases) ...p.days].any(t.isLocked), isFalse);
    });
  });

  group('plan screen', () {
    Future<List<String>> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 3200);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        'user_active_plan': jsonEncode(_plan.toJson()),
      });
      final sp = await SharedPreferences.getInstance();
      final opened = <String>[];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: PlanScreen()),
          ),
          GoRoute(
            path: '/day/:weekday',
            builder: (_, state) {
              opened.add(state.matchedLocation);
              return const Scaffold(body: Text('DAY SCREEN'));
            },
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sp),
            clockProvider.overrideWithValue(
              () => _start.add(const Duration(hours: 9)),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      return opened;
    }

    testWidgets('tapping a later day explains it, and Got it closes it', (
      tester,
    ) async {
      final opened = await pump(tester);
      await tester.tap(find.text('Day 2'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Finish Day 1 first'), findsOneWidget);
      expect(
        find.textContaining('Day 2 opens once you have completed Day 1'),
        findsOneWidget,
      );
      expect(opened, isEmpty);

      await tester.tap(find.text('Got it'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Finish Day 1 first'), findsNothing);
      expect(opened, isEmpty);
    });

    testWidgets('locked days show a lock instead of an arrow', (tester) async {
      await pump(tester);
      expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });

    testWidgets('the day to do now still opens', (tester) async {
      final opened = await pump(tester);
      // The big card for Day 1 opens its preview from the picture.
      await tester.tap(find.text('Upper body & core').first);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Finish Day 1 first'), findsNothing);
      expect(opened, isNotEmpty);
    });
  });
}
