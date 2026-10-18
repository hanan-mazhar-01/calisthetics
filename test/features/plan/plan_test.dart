import 'package:calisthenics/core/routing/app_shell.dart';
import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/plan/domain/plan_overview.dart';
import 'package:calisthenics/features/plan/presentation/providers/plan_providers.dart';
import 'package:calisthenics/features/plan/presentation/screens/plan_screen.dart';
import 'package:calisthenics/features/plans/data/plan_templates.dart';
import 'package:calisthenics/features/plans/domain/plan_builder.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:calisthenics/features/user/domain/active_plan.dart';
import 'package:calisthenics/features/user/domain/completed_session.dart';
import 'package:calisthenics/features/user/presentation/providers/user_providers.dart';
import 'package:calisthenics/shared/widgets/premium_bottom_nav.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Wednesday 14 Oct 2026 (weekday index 2).
final _today = DateTime(2026, 10, 14, 9);
final _template = planTemplates.firstWhere(
  (t) => t.id == 'foundation-full-body',
);
const _profile = UserProfile(daysPerWeek: 3);
final _plan = ActivePlan(
  templateId: _template.id,
  startDate: DateTime(2026, 10, 12),
  profile: _profile,
);

CompletedSession _done(DateTime at, {String? id}) => CompletedSession(
  finishedAt: at,
  templateId: id ?? _template.id,
  sessionName: 's',
  durationSeconds: 600,
  exerciseNumbers: const [1],
);

PlanOverview _build(List<CompletedSession> history, {ActivePlan? plan}) {
  final p = plan ?? _plan;
  return PlanOverview.build(
    template: _template,
    plan: p,
    week: const PlanBuilder().buildWeek(
      _template,
      _profile,
      week: p.weekNumberOn(_today),
      stageIndex: p.stageIndex,
    ),
    history: history,
    today: _today,
  );
}

void main() {
  test('today is highlighted, rest days stay rest, others upcoming', () {
    final o = _build([]);
    // 3 days/week trains Mon, Wed, Fri.
    expect(o.days[0].status, DayStatus.missed);
    expect(o.days[1].status, DayStatus.rest);
    expect(o.days[2].status, DayStatus.today);
    expect(o.days[4].status, DayStatus.upcoming);
    expect(o.todayView?.day.weekday, 2);
  });

  test('a session finished earlier counts as done', () {
    final o = _build([
      _done(DateTime(2026, 10, 12, 8)),
      _done(DateTime(2026, 10, 14, 8)),
    ]);
    expect(o.days[0].status, DayStatus.done);
    expect(o.days[2].status, DayStatus.done);
    expect(o.todayView, isNull);
  });

  test('stage percent is sessions done over planned in the 4-week block', () {
    // 3 days × 4 weeks = 12 planned; 3 done = 25%. Other plans ignored.
    final o = _build([
      _done(DateTime(2026, 10, 12)),
      _done(DateTime(2026, 10, 14)),
      _done(DateTime(2026, 10, 15)),
      _done(DateTime(2026, 10, 13), id: 'daily'),
    ]);
    expect(o.cycleSessionsPlanned, 12);
    expect(o.cycleSessionsDone, 3);
    expect(o.stages.single.percent, 25);
    expect(o.levelComplete, isFalse);
  });

  test('level complete once the final stage block is fully done', () {
    final history = [
      for (var i = 0; i < 12; i++) _done(DateTime(2026, 10, 12 + i)),
    ];
    final o = _build(history);
    expect(o.stages.single.percent, 100);
    expect(o.levelComplete, isTrue);
  });

  test('earlier stages read 100%, later ones 0%', () {
    final skill = planTemplates.firstWhere((t) => t.stages.length == 3);
    final plan = ActivePlan(
      templateId: skill.id,
      startDate: DateTime(2026, 10, 12),
      profile: _profile,
      stageIndex: 1,
    );
    final o = PlanOverview.build(
      template: skill,
      plan: plan,
      week: const PlanBuilder().buildWeek(
        skill,
        _profile,
        week: 1,
        stageIndex: 1,
      ),
      history: const [],
      today: _today,
    );
    expect(o.stages.map((s) => s.percent), [100, 0, 0]);
    expect(o.stages.map((s) => s.state), [
      StageState.done,
      StageState.current,
      StageState.upcoming,
    ]);
    expect(o.levelComplete, isFalse);
  });

  test('target labels', () {
    expect(
      targetLabel(const BuiltItem(exerciseNumber: 1, sets: 3, reps: 8)),
      '3 × 30 s',
    );
    expect(
      targetLabel(
        const BuiltItem(
          exerciseNumber: 1,
          sets: 2,
          holdSeconds: 30,
          perSide: true,
        ),
      ),
      '2 × 30 s each side',
    );
  });

  test('free by default', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    expect(c.read(isPremiumProvider), isFalse);
  });

  Future<ProviderScope> scope(
    Widget child, {
    Map<String, Object>? prefs,
  }) async {
    SharedPreferences.setMockInitialValues(prefs ?? {});
    final sp = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        clockProvider.overrideWithValue(() => _today),
      ],
      child: MaterialApp(theme: AppTheme.light, home: child),
    );
  }

  testWidgets('empty state without a plan', (tester) async {
    await tester.pumpWidget(await scope(const Scaffold(body: PlanScreen())));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('No plan yet'), findsOneWidget);
    expect(find.text('Choose a plan'), findsOneWidget);
  });

  testWidgets('nav bar shows the active label and reports taps', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      await scope(
        StatefulBuilder(
          builder: (context, set) => Scaffold(
            bottomNavigationBar: PremiumBottomNavigationBar(
              currentIndex: selected,
              items: appTabs,
              onItemSelected: (i) => set(() => selected = i),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Progress'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Progress'));
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(find.text('Progress'), findsOneWidget);
  });
  for (final dark in [false, true]) {
    testWidgets('plan tab with a plan renders (dark: $dark)', (tester) async {
      tester.view.physicalSize = const Size(900, 3200);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        'user_active_plan': jsonEncode(_plan.toJson()),
      });
      final sp = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sp),
            clockProvider.overrideWithValue(() => _today),
          ],
          child: MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: const Scaffold(body: PlanScreen()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Full-Body Foundation'), findsOneWidget);
      expect(find.text('Start Training'), findsOneWidget);
      expect(find.textContaining('Phase 1'), findsOneWidget);
      expect(find.text('Day 2'), findsOneWidget);
      expect(find.text('Add More Plan'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
