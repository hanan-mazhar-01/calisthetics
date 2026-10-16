import '../../../shared/models/calisthenics_skill.dart';
import '../../exercises/domain/exercise.dart';
import '../../exercises/domain/exercise_lookup.dart';
import '../../plans/domain/plan_template.dart';
import '../../user/domain/completed_session.dart';
import '../../user/domain/user_stats.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Month calendar helpers (weeks start on Monday).
class MonthCalendar {
  const MonthCalendar(this.month);

  /// Any date in the month.
  final DateTime month;

  int get daysInMonth => DateTime(month.year, month.month + 1, 0).day;

  /// Empty cells before day 1 (Monday = 0).
  int get leadingBlanks => DateTime(month.year, month.month, 1).weekday - 1;

  /// Days of the month with at least one finished workout.
  Set<int> trainedDays(List<CompletedSession> history) => {
    for (final s in history)
      if (s.finishedAt.year == month.year && s.finishedAt.month == month.month)
        s.finishedAt.day,
  };
}

class PersonalRecords {
  const PersonalRecords({
    required this.plankSeconds,
    required this.longestStreak,
    required this.longestSessionMinutes,
    required this.bestWeekWorkouts,
  });

  final int plankSeconds;
  final int longestStreak;
  final int longestSessionMinutes;

  /// Most workouts in one Monday–Sunday week.
  final int bestWeekWorkouts;

  factory PersonalRecords.from(
    List<CompletedSession> history,
    UserStats stats,
    Map<String, int> records,
  ) {
    final perWeek = <DateTime, int>{};
    var longest = 0;
    for (final s in history) {
      final d = dateOnly(s.finishedAt);
      final monday = d.subtract(Duration(days: d.weekday - 1));
      perWeek[monday] = (perWeek[monday] ?? 0) + 1;
      final m = (s.durationSeconds / 60).round();
      if (m > longest) longest = m;
    }
    return PersonalRecords(
      plankSeconds: records['plankSeconds'] ?? 0,
      longestStreak: stats.longestStreak,
      longestSessionMinutes: longest,
      bestWeekWorkouts: perWeek.values.fold(0, (a, b) => a > b ? a : b),
    );
  }
}

/// Every rung of a skill ladder in order, including rungs that reuse a
/// foundation exercise's video (so the wall push-up counts as rung one).
List<Exercise> _rungs(String skillId) => exercisesInSection('skill-$skillId');

class LadderProgress {
  const LadderProgress({
    required this.skillId,
    required this.label,
    required this.rungCount,
    required this.currentRung,
  });

  final String skillId;
  final String label;
  final int rungCount;

  /// 0-based index of the highest rung reached, or -1 when not started.
  final int currentRung;

  bool get started => currentRung >= 0;
  String? get currentName => started ? _rungs(skillId)[currentRung].name : null;
}

/// Highest rung per skill reached through trained exercises in [history] or
/// through the stage of the active plan when it is that skill's plan.
List<LadderProgress> ladderProgress({
  required List<CompletedSession> history,
  PlanTemplate? template,
  int stageIndex = 0,
}) {
  // Repeated entries share a video with their original, so compare by video.
  final done = {
    for (final s in history)
      for (final n in s.exerciseNumbers) exerciseByNumber(n).videoNumber,
  };
  final planNumbers = <int>{};
  if (template != null && template.skillId != null) {
    final stage =
        template.stages[stageIndex.clamp(0, template.stages.length - 1)];
    for (final s in stage.sessions) {
      for (final i in s.items) {
        planNumbers.add(exerciseByNumber(i.exerciseNumber).videoNumber);
      }
    }
  }
  return [
    for (final skill in calisthenicsSkills)
      () {
        final ladder = _rungs(skill.id);
        var best = -1;
        for (var i = 0; i < ladder.length; i++) {
          final n = ladder[i].videoNumber;
          final fromPlan =
              template?.skillId == skill.id && planNumbers.contains(n);
          if (done.contains(n) || fromPlan) best = i;
        }
        return LadderProgress(
          skillId: skill.id,
          label: skill.label,
          rungCount: ladder.length,
          currentRung: best,
        );
      }(),
  ];
}
