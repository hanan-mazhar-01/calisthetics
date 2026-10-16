import 'package:calisthenics/features/plan/domain/plan_timeline.dart';
import 'package:calisthenics/features/plans/data/plan_templates.dart';
import 'package:calisthenics/features/plans/domain/plan_builder.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:calisthenics/features/profile/domain/achievement_evaluator.dart';
import 'package:calisthenics/features/profile/domain/profile_stats.dart';
import 'package:calisthenics/features/progress/domain/progress_models.dart';
import 'package:calisthenics/features/user/domain/active_plan.dart';
import 'package:calisthenics/features/user/domain/completed_session.dart';
import 'package:calisthenics/features/user/domain/plank_attempt.dart';
import 'package:calisthenics/features/user/domain/user_stats.dart';
import 'package:flutter_test/flutter_test.dart';

CompletedSession _s(DateTime at) => CompletedSession(
  finishedAt: at,
  templateId: 'foundation-full-body',
  sessionName: 'S',
  durationSeconds: 600,
  exerciseNumbers: const [1],
);

void main() {
  final template = planTemplates.firstWhere(
    (t) => t.id == 'foundation-full-body',
  );
  const profile = UserProfile(daysPerWeek: 3); // Mon, Wed, Fri
  final plan = ActivePlan(
    templateId: template.id,
    startDate: DateTime(2026, 10, 12),
    profile: profile,
  );
  final wed = DateTime(2026, 10, 14);

  List<Achievement> achievements(int longest) =>
      const AchievementEvaluator().evaluate(
        history: const [],
        stats: UserStats(
          workouts: 0,
          totalMinutes: 0,
          currentStreak: 0,
          longestStreak: longest,
        ),
        records: const {},
      );

  test('next streak milestone reads the evaluator thresholds', () {
    expect(nextStreakMilestone(achievements(0), 0)?.target, 3);
    expect(nextStreakMilestone(achievements(0), 3)?.target, 7);
    expect(nextStreakMilestone(achievements(0), 6)?.target, 7);
    expect(nextStreakMilestone(achievements(0), 7)?.target, 14);
    expect(nextStreakMilestone(achievements(0), 14)?.target, 30);
    expect(nextStreakMilestone(achievements(0), 30)?.target, 100);
    expect(nextStreakMilestone(achievements(0), 100), isNull);
  });

  test('week strip marks done, today, rest, planned and other', () {
    final week = const PlanBuilder().buildWeek(
      template,
      profile,
      week: plan.weekNumberOn(wed),
      stageIndex: 0,
    );
    final strip = weekStrip(
      history: [_s(DateTime(2026, 10, 12, 8))],
      today: wed,
      week: week,
      planStart: plan.startDate,
    );
    expect(
      [for (final d in strip) d.state],
      [
        StreakDayState.done, // Mon trained
        StreakDayState.rest, // Tue
        StreakDayState.today, // Wed
        StreakDayState.rest, // Thu
        StreakDayState.planned, // Fri
        StreakDayState.rest, // Sat
        StreakDayState.rest, // Sun
      ],
    );
    // No plan: only done / today / other.
    final bare = weekStrip(history: const [], today: wed, week: null);
    expect(bare[0].state, StreakDayState.other);
    expect(bare[2].state, StreakDayState.today);
  });

  test('planned days of the month are the plan\'s remaining training days', () {
    final timeline = PlanTimeline.build(
      template: template,
      plan: plan,
      history: [_s(DateTime(2026, 10, 12))],
      today: wed,
    );
    expect(plannedDaysInMonth(timeline, wed), {16, 19, 21, 23, 26, 28, 30});
    expect(plannedDaysInMonth(null, wed), isEmpty);
  });

  test('workouts in month counts sessions of that month only', () {
    final h = [
      _s(DateTime(2026, 10, 1)),
      _s(DateTime(2026, 10, 1, 18)),
      _s(DateTime(2026, 9, 30)),
    ];
    expect(workoutsInMonth(h, wed), 2);
  });

  group('plank trend', () {
    PlankAttempt a(DateTime d, int s) => PlankAttempt(at: d, seconds: s);

    test('none gives null; one attempt gives one point and no gain', () {
      expect(PlankTrend.from(const []), isNull);
      final t = PlankTrend.from([a(wed, 42)])!;
      expect(t.points.length, 1);
      expect(t.best, 42);
      expect(t.gain, 0);
    });

    test('best per week, week index since the first attempt, gain', () {
      final t = PlankTrend.from([
        a(DateTime(2026, 10, 1), 42), // week of 28 Sep: Wk 1
        a(DateTime(2026, 10, 2), 40),
        a(DateTime(2026, 10, 14), 50), // Wk 3 (gap week skipped)
        a(DateTime(2026, 10, 15), 58),
      ])!;
      expect([for (final p in t.points) p.weekIndex], [1, 3]);
      expect([for (final p in t.points) p.seconds], [42, 58]);
      expect(t.best, 58);
      expect(t.gain, 16);
    });
  });

  group('featured ladder', () {
    test('most trained skill wins; else plan skill; else push-up', () {
      final none = ladderProgress(history: const []);
      expect(
        featuredLadder(
          byHistory: none,
          withPlan: none,
          planSkillId: null,
        ).skillId,
        'push-up',
      );
      final withPlan = ladderProgress(
        history: const [],
        template: planTemplates.firstWhere((t) => t.skillId == 'pull-up'),
      );
      expect(
        featuredLadder(
          byHistory: none,
          withPlan: withPlan,
          planSkillId: 'pull-up',
        ).skillId,
        'pull-up',
      );
    });
  });
}
