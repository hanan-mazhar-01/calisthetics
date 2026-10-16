import 'package:calisthenics/features/profile/domain/achievement_evaluator.dart';
import 'package:calisthenics/features/profile/domain/profile_stats.dart';
import 'package:calisthenics/features/user/domain/completed_session.dart';
import 'package:calisthenics/features/user/domain/user_stats.dart';
import 'package:flutter_test/flutter_test.dart';

CompletedSession s(DateTime d, {int secs = 600, List<int> ex = const [1]}) =>
    CompletedSession(
      finishedAt: d,
      templateId: 't',
      sessionName: 'n',
      durationSeconds: secs,
      exerciseNumbers: ex,
    );

void main() {
  final today = DateTime(2026, 10, 12);

  test('no history: nothing unlocked', () {
    final stats = UserStats.from([], today: today);
    final list = const AchievementEvaluator().evaluate(
      history: [],
      stats: stats,
      records: {},
    );
    expect(list.where((a) => a.unlocked), isEmpty);
  });

  test('unlocks from real data', () {
    final history = [
      for (var i = 0; i < 7; i++) s(today.subtract(Duration(days: i))),
    ];
    final stats = UserStats.from(history, today: today);
    final list = const AchievementEvaluator().evaluate(
      history: history,
      stats: stats,
      records: {'plankSeconds': 45},
    );
    bool un(String id) => list.firstWhere((a) => a.id == id).unlocked;
    expect(un('first-workout'), isTrue);
    expect(un('streak-7'), isTrue);
    expect(un('streak-30'), isFalse);
    expect(un('workouts-10'), isFalse);
    expect(un('plank-30'), isTrue);
    expect(un('plank-60'), isFalse);
    expect(un('minutes-100'), isFalse);
  });

  test('month calendar', () {
    final cal = MonthCalendar(DateTime(2026, 10, 15));
    expect(cal.daysInMonth, 31);
    expect(cal.leadingBlanks, 3); // 1 Oct 2026 is a Thursday
    expect(
      cal.trainedDays([s(DateTime(2026, 10, 3)), s(DateTime(2026, 9, 30))]),
      {3},
    );
  });

  test('personal records', () {
    final h = [
      s(DateTime(2026, 10, 12), secs: 1200), // Monday
      s(DateTime(2026, 10, 14)),
      s(DateTime(2026, 10, 5)),
    ];
    final r = PersonalRecords.from(h, UserStats.from(h, today: today), {
      'plankSeconds': 40,
    });
    expect(r.plankSeconds, 40);
    expect(r.longestSessionMinutes, 20);
    expect(r.bestWeekWorkouts, 2);
  });

  test('ladder progress uses trained exercises', () {
    expect(ladderProgress(history: []).every((l) => !l.started), isTrue);
    final p = ladderProgress(
      history: [
        s(today, ex: [1]),
      ],
    );
    expect(p.firstWhere((l) => l.skillId == 'push-up').started, isTrue);
  });
}
