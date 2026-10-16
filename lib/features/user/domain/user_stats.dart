import 'completed_session.dart';

/// Real metrics derived from history — never steps, calories, height or weight.
class UserStats {
  const UserStats({
    required this.workouts,
    required this.totalMinutes,
    required this.currentStreak,
    required this.longestStreak,
  });

  final int workouts;
  final int totalMinutes;

  /// Workout days in a row, counting back from today (or yesterday if today
  /// isn't trained yet). Planned rest days neither add to the streak nor
  /// break it; a missed training day does.
  final int currentStreak;
  final int longestStreak;

  /// [restWeekdays] are the weekdays (0 = Monday) the user's plan leaves free.
  /// With none given (no plan) every day counts, i.e. plain consecutive days.
  factory UserStats.from(
    List<CompletedSession> history, {
    required DateTime today,
    Set<int> restWeekdays = const {},
  }) {
    DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    final trained = {for (final s in history) dateOnly(s.finishedAt)};
    final t = dateOnly(today);

    bool isRest(DateTime d) =>
        !trained.contains(d) && restWeekdays.contains(d.weekday - 1);

    var current = 0;
    var longest = 0;
    if (trained.isNotEmpty) {
      final first = (trained.toList()..sort()).first;

      // Current: walk back from today; today being untrained doesn't break it yet.
      var cursor = t;
      while (!cursor.isBefore(first)) {
        if (trained.contains(cursor)) {
          current++;
        } else if (!(cursor == t) && !isRest(cursor)) {
          break;
        }
        cursor = cursor.subtract(const Duration(days: 1));
      }

      // Longest: walk forward, resetting on every missed training day.
      var run = 0;
      for (var d = first; !d.isAfter(t); d = d.add(const Duration(days: 1))) {
        if (trained.contains(d)) {
          run++;
          if (run > longest) longest = run;
        } else if (!isRest(d) && d != t) {
          run = 0;
        }
      }
    }

    return UserStats(
      workouts: history.length,
      totalMinutes: history.fold<int>(
        0,
        (sum, s) => sum + (s.durationSeconds / 60).round(),
      ),
      currentStreak: current,
      longestStreak: longest,
    );
  }
}
