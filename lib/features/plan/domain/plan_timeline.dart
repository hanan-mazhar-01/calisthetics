import '../../plans/domain/plan_builder.dart';
import '../../plans/domain/plan_template.dart';
import '../../user/domain/active_plan.dart';
import '../../user/domain/completed_session.dart';

enum TimelineStatus { done, today, upcoming, missed }

/// One training day of the plan. Rest days don't appear: "Day N" counts
/// training days only.
class TimelineDay {
  const TimelineDay({
    required this.dayNumber,
    required this.date,
    required this.weekNumber,
    required this.weekday,
    required this.session,
    required this.status,
  });

  /// 1-based count of training days since the plan began.
  final int dayNumber;
  final DateTime date;

  /// Plan week (1-based, Monday-aligned) and weekday (0 = Monday).
  final int weekNumber;
  final int weekday;
  final BuiltSession session;
  final TimelineStatus status;

  TimelineDay copyWith(TimelineStatus status) => TimelineDay(
    dayNumber: dayNumber,
    date: date,
    weekNumber: weekNumber,
    weekday: weekday,
    session: session,
    status: status,
  );
}

/// One plan week, shown as "Phase N (Day a–b)".
class TimelinePhase {
  const TimelinePhase({
    required this.index,
    required this.weekNumber,
    required this.days,
  });

  final int index;
  final int weekNumber;
  final List<TimelineDay> days;

  int get firstDay => days.first.dayNumber;
  int get lastDay => days.last.dayNumber;
  int get doneCount =>
      days.where((d) => d.status == TimelineStatus.done).length;
  double get fraction => days.isEmpty ? 0 : doneCount / days.length;
  int get percent => (fraction * 100).round();
}

/// The current 4-week block of a plan as phases of training days, with the
/// day to start next marked as the hero. Pure: built from plan + history.
class PlanTimeline {
  /// Training days of week 1 that fall before the plan began (it started
  /// mid-week), so the plan's first session lands on its first real day.
  /// Calendar date of [weekday] (0 = Monday) in plan week [week].
  /// [weekday] is the day's position in the plan week (0 = the weekday the
  /// plan began on).
  static DateTime dateOf(ActivePlan plan, int week, int weekday) {
    final start = plan.startDay;
    return DateTime(
      start.year,
      start.month,
      start.day + (week - 1) * 7 + weekday,
    );
  }

  /// Plan weeks start on the plan's first day, so no session ever falls
  /// before it: nothing to skip.
  static int leadingSkip(ActivePlan plan) => 0;

  const PlanTimeline({required this.phases, required this.hero});

  final List<TimelinePhase> phases;

  /// Next training day that isn't done and isn't in the past, or null when
  /// the block is finished.
  final TimelineDay? hero;

  /// A day is locked until the one to do now ([hero]) is finished: every day
  /// after the hero. Days before it are done or already missed (a missed day
  /// never blocks the rest, or one skipped day would stall the whole plan).
  bool isLocked(TimelineDay day) {
    final next = hero;
    return next != null && day.dayNumber > next.dayNumber;
  }

  /// Training days in this 4-week block, and how many are done.
  int get totalDays => phases.fold(0, (sum, p) => sum + p.days.length);
  int get doneDays => phases.fold(0, (sum, p) => sum + p.doneCount);

  bool get blockComplete =>
      phases.every((p) => p.days.every((d) => d.status == TimelineStatus.done));

  factory PlanTimeline.build({
    required PlanTemplate template,
    required ActivePlan plan,
    required List<CompletedSession> history,
    required DateTime today,
  }) {
    const builder = PlanBuilder();
    final todayDate = DateTime(today.year, today.month, today.day);
    final startDay = plan.startDay;
    final currentWeek = plan.weekNumberOn(todayDate);
    final cycle = (currentWeek - 1) ~/ 4;
    final lastWeek = cycle * 4 + 4;

    final doneDates = {
      for (final s in history)
        if (plan.counts(s))
          DateTime(s.finishedAt.year, s.finishedAt.month, s.finishedAt.day),
    };

    final phases = <TimelinePhase>[];
    var dayNumber = 0;
    for (var w = 1; w <= lastWeek; w++) {
      final built = builder.buildWeek(
        template,
        plan.profile,
        week: w,
        stageIndex: plan.stageIndex,
        skipLeadingDays: w == 1 ? leadingSkip(plan) : 0,
      );
      final days = <TimelineDay>[];
      for (final d in built.days) {
        final session = d.session;
        if (session == null) continue;
        final date = DateTime(
          startDay.year,
          startDay.month,
          startDay.day + (w - 1) * 7 + d.weekday,
        );
        if (date.isBefore(plan.startDate)) continue; // before the plan began
        dayNumber++;
        final status = doneDates.contains(date)
            ? TimelineStatus.done
            : date == todayDate
            ? TimelineStatus.today
            : date.isAfter(todayDate)
            ? TimelineStatus.upcoming
            : TimelineStatus.missed;
        days.add(
          TimelineDay(
            dayNumber: dayNumber,
            date: date,
            weekNumber: w,
            weekday: d.weekday,
            session: session,
            status: status,
          ),
        );
      }
      if (w > cycle * 4 && days.isNotEmpty) {
        phases.add(
          TimelinePhase(index: w - cycle * 4, weekNumber: w, days: days),
        );
      }
    }

    // A session finished off its scheduled date (e.g. today's workout on the
    // next training day) still ticks off the earliest unfinished day.
    final scheduled = {
      for (final p in phases)
        for (final d in p.days) d.date,
    };
    // A scheduled day uses up one workout finished on its date; every other
    // workout (on an unscheduled date, or a second one on the same day, e.g.
    // doing tomorrow's session today) ticks off the earliest unfinished day.
    final perDate = <DateTime, int>{};
    for (final s in history) {
      if (!plan.counts(s)) continue;
      final d = DateTime(
        s.finishedAt.year,
        s.finishedAt.month,
        s.finishedAt.day,
      );
      perDate[d] = (perDate[d] ?? 0) + 1;
    }
    var extra = 0;
    perDate.forEach((date, count) {
      extra += scheduled.contains(date) ? count - 1 : count;
    });
    if (extra > 0) {
      for (var pi = 0; pi < phases.length && extra > 0; pi++) {
        final p = phases[pi];
        final days = <TimelineDay>[];
        for (final d in p.days) {
          if (extra > 0 && d.status != TimelineStatus.done) {
            extra--;
            days.add(d.copyWith(TimelineStatus.done));
          } else {
            days.add(d);
          }
        }
        phases[pi] = TimelinePhase(
          index: p.index,
          weekNumber: p.weekNumber,
          days: days,
        );
      }
    }

    TimelineDay? hero;
    for (final p in phases) {
      for (final d in p.days) {
        if (hero == null &&
            (d.status == TimelineStatus.today ||
                d.status == TimelineStatus.upcoming)) {
          hero = d;
        }
      }
    }
    return PlanTimeline(phases: phases, hero: hero);
  }
}
