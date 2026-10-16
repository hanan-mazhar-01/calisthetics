import 'package:calisthenics/features/progress/presentation/widgets/streak_overview.dart';
import 'package:calisthenics/features/user/domain/completed_session.dart';
import 'package:calisthenics/features/user/domain/partial_effort.dart';
import 'package:flutter_test/flutter_test.dart';

CompletedSession _s(DateTime at, {int seconds = 900, int exercises = 2}) =>
    CompletedSession(
      finishedAt: at,
      templateId: 't',
      sessionName: 's',
      durationSeconds: seconds,
      exerciseNumbers: List.filled(exercises, 1),
    );

void main() {
  // Wednesday 14 Oct 2026.
  final today = DateTime(2026, 10, 14, 10);
  final history = [
    _s(DateTime(2026, 9, 30, 8)), // last month
    _s(DateTime(2026, 10, 3, 8)), // this month, last week
    _s(DateTime(2026, 10, 12, 8), seconds: 1200, exercises: 5), // this week
    _s(DateTime(2026, 10, 14, 8), seconds: 600, exercises: 3), // this week
  ];

  test('All counts every finished workout', () {
    final t = RangeTotals.of(history, StreakRange.all, today);
    expect(t.workouts, 4);
    expect(t.minutes, 15 + 15 + 20 + 10);
    expect(t.exercises, 2 + 2 + 5 + 3);
  });

  test('Month counts only this calendar month', () {
    final t = RangeTotals.of(history, StreakRange.month, today);
    expect(t.workouts, 3);
    expect(t.minutes, 45);
  });

  test('Week runs Monday to Sunday of this week', () {
    final t = RangeTotals.of(history, StreakRange.week, today);
    expect(t.workouts, 2);
    expect(t.minutes, 30);
    expect(t.exercises, 8);
  });

  test('quitting early adds minutes and exercises but not a workout', () {
    final early = [
      PartialEffort(at: DateTime(2026, 10, 14, 9), seconds: 300, exercises: 2),
      PartialEffort(at: DateTime(2026, 9, 1, 9), seconds: 600, exercises: 4),
    ];
    final week = RangeTotals.of(
      history,
      StreakRange.week,
      today,
      partial: early,
    );
    expect(week.workouts, 2); // unchanged
    expect(week.minutes, 30 + 5);
    expect(week.exercises, 8 + 2);
    final all = RangeTotals.of(history, StreakRange.all, today, partial: early);
    expect(all.workouts, 4);
    expect(all.minutes, 60 + 5 + 10);
    expect(all.exercises, 12 + 2 + 4);
  });

  test('no history gives zeros', () {
    final t = RangeTotals.of(const [], StreakRange.all, today);
    expect((t.workouts, t.minutes, t.exercises), (0, 0, 0));
  });
}
