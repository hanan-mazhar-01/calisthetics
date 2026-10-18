import '../../exercises/domain/exercise_lookup.dart';
import '../../plans/domain/plan_builder.dart';
import '../../profile/domain/achievement_evaluator.dart';
import '../../profile/domain/profile_stats.dart';
import '../../user/domain/completed_session.dart';
import '../../user/domain/plank_attempt.dart';

DateTime _date(DateTime d) => DateTime(d.year, d.month, d.day);

// ── Streak ──────────────────────────────────────────────────────────

/// The next streak badge: the smallest `streak-N` achievement target above
/// [currentStreak]. Reads the evaluator's own targets, so the thresholds live
/// in one place. Null once every streak badge is within reach of the streak.
({int target, String title})? nextStreakMilestone(
  List<Achievement> achievements,
  int currentStreak,
) {
  Achievement? best;
  for (final a in achievements) {
    if (!a.id.startsWith('streak-') || a.target <= currentStreak) continue;
    if (best == null || a.target < best.target) best = a;
  }
  return best == null ? null : (target: best.target, title: best.title);
}

enum StreakDayState { done, today, rest, planned, other }

class StreakDay {
  const StreakDay({
    required this.date,
    required this.initial,
    required this.state,
  });
  final DateTime date;
  final String initial;
  final StreakDayState state;
}

/// Monday–Sunday strip for the week containing [today].
///  * done: a workout was finished that day
///  * today: today, not yet trained
///  * rest: a rest day of the active plan (never breaks the streak)
///  * planned: an upcoming training day of the plan
///  * other: everything else (missed days, days before the plan, no plan)
List<StreakDay> weekStrip({
  required List<CompletedSession> history,
  required DateTime today,
  required BuiltWeek? week,
  DateTime? planStart,
}) {
  const initials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final t = _date(today);
  final monday = DateTime(t.year, t.month, t.day - (t.weekday - 1));
  final trained = {for (final s in history) _date(s.finishedAt)};
  return [
    for (var i = 0; i < 7; i++)
      () {
        final d = DateTime(monday.year, monday.month, monday.day + i);
        final inPlan =
            week != null && (planStart == null || !d.isBefore(planStart));
        // Plan weeks start on the plan's first day; every week has the same
        // pattern, so the day's place in its plan week picks its slot.
        final planned = inPlan && week.days.length == 7
            ? week.days[((planStart == null
                              ? d.weekday - 1
                              : d.difference(planStart).inDays) %
                          7 +
                      7) %
                  7]
            : null;
        final state = trained.contains(d)
            ? StreakDayState.done
            : d == t
            ? StreakDayState.today
            : planned != null && planned.isRest
            ? StreakDayState.rest
            : planned != null && d.isAfter(t)
            ? StreakDayState.planned
            : StreakDayState.other;
        return StreakDay(date: d, initial: initials[i], state: state);
      }(),
  ];
}

// ── Calendar ────────────────────────────────────────────────────────

/// Finished workouts (not days) in [today]'s month.
int workoutsInMonth(List<CompletedSession> history, DateTime today) => history
    .where(
      (s) =>
          s.finishedAt.year == today.year && s.finishedAt.month == today.month,
    )
    .length;

// ── Plank ───────────────────────────────────────────────────────────

class PlankPoint {
  const PlankPoint({required this.weekIndex, required this.seconds});

  /// 1-based week count since the first attempt's week.
  final int weekIndex;

  /// Best hold of that week.
  final int seconds;
}

class PlankTrend {
  const PlankTrend({
    required this.points,
    required this.best,
    required this.first,
    required this.attempts,
  });

  /// Best plank per week that has attempts, oldest first (at most [maxPoints]).
  final List<PlankPoint> points;
  final int best;
  final int first;
  final int attempts;

  static const maxPoints = 6;

  /// Seconds gained since the very first attempt (0 if none).
  int get gain => best > first ? best - first : 0;

  static PlankTrend? from(List<PlankAttempt> attempts) {
    final valid = [
      for (final a in attempts)
        if (a.seconds > 0) a,
    ]..sort((a, b) => a.at.compareTo(b.at));
    if (valid.isEmpty) return null;
    DateTime monday(DateTime d) {
      final x = _date(d);
      return DateTime(x.year, x.month, x.day - (x.weekday - 1));
    }

    final firstMonday = monday(valid.first.at);
    final perWeek = <int, int>{};
    for (final a in valid) {
      final w = monday(a.at).difference(firstMonday).inDays ~/ 7 + 1;
      final cur = perWeek[w] ?? 0;
      if (a.seconds > cur) perWeek[w] = a.seconds;
    }
    final keys = perWeek.keys.toList()..sort();
    final shown = keys.length > maxPoints
        ? keys.sublist(keys.length - maxPoints)
        : keys;
    return PlankTrend(
      points: [
        for (final k in shown) PlankPoint(weekIndex: k, seconds: perWeek[k]!),
      ],
      best: valid.map((a) => a.seconds).reduce((a, b) => a > b ? a : b),
      first: valid.first.seconds,
      attempts: valid.length,
    );
  }
}

// ── Skill ladder ────────────────────────────────────────────────────

/// The ladder to feature: the skill with the highest trained rung in
/// [byHistory]; else the active plan's skill (read from [withPlan]); else
/// push-up, not started. Ties go to the plan's skill, then to list order.
LadderProgress featuredLadder({
  required List<LadderProgress> byHistory,
  required List<LadderProgress> withPlan,
  String? planSkillId,
}) {
  LadderProgress? best;
  for (final l in byHistory) {
    if (!l.started) continue;
    if (best == null ||
        l.currentRung > best.currentRung ||
        (l.currentRung == best.currentRung && l.skillId == planSkillId)) {
      best = l;
    }
  }
  if (best != null) return best;
  if (planSkillId != null) {
    for (final l in withPlan) {
      if (l.skillId == planSkillId) return l;
    }
  }
  return byHistory.firstWhere((l) => l.skillId == 'push-up');
}

/// Names of the rungs of [skillId], in the same order [LadderProgress] indexes.
List<String> rungNames(String skillId) => [
  for (final e in exercisesInSection('skill-$skillId')) e.name,
];
