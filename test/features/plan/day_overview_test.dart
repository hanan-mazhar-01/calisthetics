import 'dart:convert';

import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/exercises/domain/exercise_lookup.dart';
import 'package:calisthenics/features/plan/presentation/screens/day_overview_screen.dart';
import 'package:calisthenics/features/plans/data/plan_templates.dart';
import 'package:calisthenics/features/plans/domain/plan_builder.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:calisthenics/features/user/domain/active_plan.dart';
import 'package:calisthenics/features/user/presentation/providers/user_providers.dart';
import 'package:calisthenics/features/workout/domain/workout_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _today = DateTime(2026, 10, 14, 9);
final _template = planTemplates.firstWhere(
  (t) => t.id == 'foundation-full-body',
);
final _plan = ActivePlan(
  templateId: _template.id,
  startDate: DateTime(2026, 10, 12),
  profile: const UserProfile(daysPerWeek: 3),
);

class _FixedPlan extends ActivePlanNotifier {
  @override
  ActivePlan? build() => _plan;
}

void main() {
  final week = const PlanBuilder().buildWeek(
    _template,
    _plan.profile,
    week: _plan.weekNumberOn(_today),
    stageIndex: _plan.stageIndex,
  );
  final weekday = week.days.indexWhere((d) => d.session != null);
  final session = week.days[weekday].session!;

  Object? pushed;
  Future<void> pump(
    WidgetTester tester, {
    int? weekParam,
    Map<String, Object> prefs = const {},
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    pushed = null;
    final router = GoRouter(
      initialLocation: '/day',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        GoRoute(
          path: '/day',
          builder: (_, _) =>
              DayOverviewScreen(weekday: weekday, week: weekParam),
        ),
        GoRoute(
          path: '/workout',
          builder: (_, s) {
            pushed = s.extra;
            return const Scaffold(body: Text('workout-route'));
          },
        ),
        GoRoute(
          path: '/exercise/:n',
          builder: (_, s) =>
              Scaffold(body: Text('exercise-${s.pathParameters['n']}')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sp),
          clockProvider.overrideWithValue(() => _today),
          activePlanProvider.overrideWith(_FixedPlan.new),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('shows sections with counts and no calorie claims', (
    tester,
  ) async {
    await pump(tester);
    expect(
      find.textContaining(
        'Warm up · ${session.warmUp.length}',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Main · ', findRichText: true), findsOneWidget);
    expect(find.text(session.name), findsOneWidget);
    expect(find.textContaining('Mins'), findsOneWidget);
    expect(find.textContaining('Kcal'), findsNothing);
    expect(find.text('START'), findsOneWidget);
  });

  testWidgets('a later week opens that week\'s workout, not this week\'s', (
    tester,
  ) async {
    final w3 = const PlanBuilder().buildWeek(
      _template,
      _plan.profile,
      week: 3,
      stageIndex: _plan.stageIndex,
    );
    final later = w3.days[weekday].session!;
    expect(
      [...later.warmUp, ...later.items.map((i) => i.exerciseNumber)],
      isNot([...session.warmUp, ...session.items.map((i) => i.exerciseNumber)]),
    );
    await pump(tester, weekParam: 3);
    expect(
      find.textContaining(
        'Warm up · ${later.warmUp.length}',
        findRichText: true,
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('day-start')));
    await tester.pump(const Duration(milliseconds: 500));
    final req = pushed as WorkoutRequest;
    expect(req.session.warmUp, later.warmUp);
    expect(
      req.session.items.map((i) => i.exerciseNumber),
      later.items.map((i) => i.exerciseNumber),
    );
  });

  testWidgets('START pushes the workout route', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('day-start')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('workout-route'), findsOneWidget);
    expect(pushed, isA<WorkoutRequest>());
  });

  testWidgets('hero fades out as the list collapses', (tester) async {
    await pump(tester);
    double heroOpacity() =>
        tester.widget<Opacity>(find.byKey(const ValueKey('day-hero'))).opacity;
    expect(heroOpacity(), 1);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pump(const Duration(milliseconds: 500));
    expect(heroOpacity(), 0);
    expect(find.byKey(const ValueKey('day-back')), findsOneWidget);
  });

  testWidgets('music button toggles the setting', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('day-music')));
    await tester.pump();
    expect(find.byTooltip('Turn music on'), findsNothing);
    expect(find.bySemanticsLabel('Turn music on'), findsOneWidget);
  });

  testWidgets('tapping an exercise row only previews: nothing opens', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text(exerciseByNumber(session.warmUp.first).name));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('exercise-'), findsNothing);
    expect(pushed, isNull);
    expect(find.text('START'), findsOneWidget);
  });

  // Monday 12 Oct is the plan's first day (plan weeks start on its first day).
  const key = 'foundation-full-body|2026-10-12';
  final finishedOn12th = jsonEncode([
    {
      'finishedAt': DateTime(2026, 10, 12, 8).toIso8601String(),
      'templateId': 'foundation-full-body',
      'sessionName': 's',
      'durationSeconds': 600,
      'exerciseNumbers': [1],
    },
  ]);

  testWidgets('an open day left half-way says so and offers RESUME', (
    tester,
  ) async {
    await pump(tester, prefs: {'user_partial_progress': '{"$key":40}'});
    expect(find.text('40% done'), findsOneWidget);
    expect(find.text('RESUME'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('day-start')));
    await tester.pump(const Duration(milliseconds: 500));
    expect((pushed as WorkoutRequest).progressKey, key);
  });

  testWidgets('a finished day ignores old half-way progress', (tester) async {
    await pump(
      tester,
      prefs: {
        'user_history': finishedOn12th,
        'user_partial_progress': '{"$key":26}',
      },
    );
    expect(find.text('26% done'), findsNothing);
    expect(find.text('RESUME'), findsNothing);
    expect(find.text('START'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('day-start')));
    await tester.pump(const Duration(milliseconds: 500));
    // Starts from the top and saves no half-way progress of its own.
    expect((pushed as WorkoutRequest).progressKey, isNull);
  });
}
