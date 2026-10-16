import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:calisthenics/features/progress/presentation/screens/progress_screen.dart';
import 'package:calisthenics/features/user/domain/active_plan.dart';
import 'package:calisthenics/features/user/domain/completed_session.dart';
import 'package:calisthenics/features/user/domain/plank_attempt.dart';
import 'package:calisthenics/features/user/presentation/providers/user_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _History extends HistoryNotifier {
  _History(this.items);
  final List<CompletedSession> items;
  @override
  List<CompletedSession> build() => items;
}

class _Plan extends ActivePlanNotifier {
  _Plan(this.plan);
  final ActivePlan? plan;
  @override
  ActivePlan? build() => plan;
}

class _Plank extends PlankHistoryNotifier {
  _Plank(this.items);
  final List<PlankAttempt> items;
  @override
  List<PlankAttempt> build() => items;
}

CompletedSession _s(DateTime at) => CompletedSession(
  finishedAt: at,
  templateId: 'foundation-full-body',
  sessionName: 'S',
  durationSeconds: 900,
  exerciseNumbers: const [1, 2],
);

Future<void> _pump(
  WidgetTester tester, {
  required ThemeData theme,
  required List<CompletedSession> history,
  required bool withPlan,
  required List<PlankAttempt> plank,
  bool disableAnimations = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(390, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final plan = withPlan
      ? ActivePlan(
          templateId: 'foundation-full-body',
          startDate: DateTime(2026, 10, 5),
          profile: const UserProfile(daysPerWeek: 3),
        )
      : null;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 14)),
        historyProvider.overrideWith(() => _History(history)),
        activePlanProvider.overrideWith(() => _Plan(plan)),
        plankHistoryProvider.overrideWith(() => _Plank(plank)),
      ],
      child: MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 1800),
            disableAnimations: disableAnimations,
          ),
          child: const Scaffold(body: ProgressScreen()),
        ),
      ),
    ),
  );
  // Looping animations (flame pulse) never settle: advance by fixed time.
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  final history = [
    _s(DateTime(2026, 10, 5, 8)),
    _s(DateTime(2026, 10, 7, 8)),
    _s(DateTime(2026, 10, 12, 8)),
  ];
  final plank = [
    PlankAttempt(at: DateTime(2026, 10, 1), seconds: 42),
    PlankAttempt(at: DateTime(2026, 10, 13), seconds: 58),
  ];

  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    testWidgets('renders with data ($name)', (tester) async {
      await _pump(
        tester,
        theme: theme,
        history: history,
        withPlan: true,
        plank: plank,
      );
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('Longest'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
      expect(find.text('Workouts'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Add Activity'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Workout History'), findsOneWidget);
      expect(find.text('Plank hold'), findsOneWidget);
      expect(find.text('58 s'), findsOneWidget);
      expect(find.text('+16 s since day 1'), findsOneWidget);
      expect(find.text('Skill ladder'), findsNothing); // removed
      expect(tester.takeException(), isNull);

      // Switching the range updates the totals without errors.
      await tester.tap(find.text('Month'));
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Week'));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('empty state: no plank card, neutral streak copy', (
    tester,
  ) async {
    await _pump(
      tester,
      theme: AppTheme.light,
      history: const [],
      withPlan: false,
      plank: const [],
    );
    expect(find.text('Plank hold'), findsNothing);
    expect(find.text('Streak'), findsOneWidget);
    expect(find.text('Active days'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one plank attempt shows the hint and no gain', (tester) async {
    await _pump(
      tester,
      theme: AppTheme.light,
      history: const [],
      withPlan: false,
      plank: [PlankAttempt(at: DateTime(2026, 10, 13), seconds: 40)],
    );
    expect(
      find.text('Test again in a few weeks to see your trend.'),
      findsOneWidget,
    );
    expect(find.textContaining('since day 1'), findsNothing);
  });

  testWidgets('reduced motion shows final state immediately', (tester) async {
    await _pump(
      tester,
      theme: AppTheme.light,
      history: history,
      withPlan: true,
      plank: plank,
      disableAnimations: true,
    );
    // Final numbers are shown at once: 3 workouts, 45 minutes, 6 exercises.
    expect(find.text('3'), findsWidgets);
    expect(find.text('45'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('See All and the streak badge open the achievements page', (
    tester,
  ) async {
    await _pump(
      tester,
      theme: AppTheme.light,
      history: history,
      withPlan: true,
      plank: plank,
    );
    expect(find.text('See All'), findsOneWidget);
    await tester.tap(find.text('See All'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('STREAK'), findsOneWidget);
    expect(find.text('WORKOUT'), findsOneWidget);
    expect(find.text('TIME'), findsOneWidget);
    expect(find.text('SKILLS'), findsOneWidget);
    expect(find.textContaining('Received'), findsOneWidget);
  });
}
