import '../../workout/domain/workout_steps.dart';
import '../../plans/domain/plan_builder.dart';
import '../../plans/domain/plan_template.dart';
import '../../user/domain/active_plan.dart';
import '../../user/domain/completed_session.dart';

enum DayStatus { rest, done, today, upcoming, missed }

enum StageState { done, current, upcoming }

class StageProgress {
  const StageProgress({
    required this.name,
    required this.level,
    required this.state,
    required this.fraction,
  });

  final String name;
  final PlanLevel level;
  final StageState state;

  /// 0–1 share complete. Finished stages are 1, upcoming ones 0, the current
  /// one is sessions done in the current 4-week cycle over sessions planned.
  final double fraction;

  int get percent => (fraction * 100).round();
}

class DayView {
  const DayView({required this.day, required this.status});
  final PlannedDay day;
  final DayStatus status;
}

/// Everything the Plan tab shows, derived from the plan, this week and history.
class PlanOverview {
  const PlanOverview({
    required this.template,
    required this.plan,
    required this.week,
    required this.days,
    required this.stages,
    required this.cycleSessionsDone,
    required this.cycleSessionsPlanned,
    required this.levelComplete,
  });

  final PlanTemplate template;
  final ActivePlan plan;
  final BuiltWeek week;
  final List<DayView> days;
  final List<StageProgress> stages;
  final int cycleSessionsDone;
  final int cycleSessionsPlanned;

  /// The final stage's current cycle is fully done: time for "Level 2".
  final bool levelComplete;

  /// The day to start now: today's workout if not done yet, else null.
  DayView? get todayView {
    for (final d in days) {
      if (d.status == DayStatus.today) return d;
    }
    return null;
  }

  factory PlanOverview.build({
    required PlanTemplate template,
    required ActivePlan plan,
    required BuiltWeek week,
    required List<CompletedSession> history,
    required DateTime today,
  }) {
    final todayDate = DateTime(today.year, today.month, today.day);
    final todayWeekday = todayDate.weekday - 1;
    final planHistory = [
      for (final s in history)
        if (plan.counts(s)) s,
    ];

    bool doneOn(DateTime date) => planHistory.any(
      (s) =>
          s.finishedAt.year == date.year &&
          s.finishedAt.month == date.month &&
          s.finishedAt.day == date.day,
    );

    final days = [
      for (final d in week.days)
        DayView(
          day: d,
          status: () {
            if (d.isRest) return DayStatus.rest;
            final date = todayDate.add(
              Duration(days: d.weekday - todayWeekday),
            );
            if (doneOn(date)) return DayStatus.done;
            if (d.weekday == todayWeekday) return DayStatus.today;
            return d.weekday > todayWeekday
                ? DayStatus.upcoming
                : DayStatus.missed;
          }(),
        ),
    ];

    // Current 4-week cycle window.
    final cycle = (week.weekNumber - 1) ~/ 4;
    final from = plan.startDate.add(Duration(days: cycle * 28));
    final to = from.add(const Duration(days: 28));
    final done = planHistory
        .where((s) => !s.finishedAt.isBefore(from) && s.finishedAt.isBefore(to))
        .length;
    final planned = plan.profile.daysPerWeek * 4;
    final cycleFraction = planned == 0 ? 0.0 : (done / planned).clamp(0.0, 1.0);

    final current = plan.stageIndex.clamp(0, template.stages.length - 1);
    final stages = [
      for (var i = 0; i < template.stages.length; i++)
        StageProgress(
          name: template.stages[i].name,
          level: template.stages[i].level,
          state: i < current
              ? StageState.done
              : i == current
              ? StageState.current
              : StageState.upcoming,
          fraction: i < current
              ? 1
              : i == current
              ? cycleFraction
              : 0,
        ),
    ];

    return PlanOverview(
      template: template,
      plan: plan,
      week: week,
      days: days,
      stages: stages,
      cycleSessionsDone: done,
      cycleSessionsPlanned: planned,
      levelComplete:
          current == template.stages.length - 1 && cycleFraction >= 1,
    );
  }
}

const weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// "12 min" style label.
String minutesLabel(int minutes) => '$minutes min';

/// "3 × 30 s" or "3 × 30 s each side" for one planned exercise.
String targetLabel(BuiltItem item) {
  // Every set is timed in the player, so rep exercises read as 30 s too.
  final target = '${item.holdSeconds ?? timedSetSeconds} s';
  return '${item.sets} × $target${item.perSide ? ' each side' : ''}';
}
