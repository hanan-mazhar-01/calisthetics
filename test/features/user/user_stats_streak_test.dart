import 'package:calisthenics/features/user/domain/completed_session.dart';
import 'package:calisthenics/features/user/domain/user_stats.dart';
import 'package:flutter_test/flutter_test.dart';

CompletedSession _s(DateTime d) => CompletedSession(
  finishedAt: d,
  templateId: 'x',
  sessionName: 's',
  durationSeconds: 600,
  exerciseNumbers: const [1],
);

void main() {
  // Mon 12, Wed 14, Fri 16 Oct 2026 are training days; Tue/Thu/Sat/Sun are rest.
  const rest = {1, 3, 5, 6};

  test('rest days neither add to the streak nor break it', () {
    final h = [
      _s(DateTime(2026, 10, 12)),
      _s(DateTime(2026, 10, 14)),
      _s(DateTime(2026, 10, 16)),
    ];
    final stats = UserStats.from(
      h,
      today: DateTime(2026, 10, 17),
      restWeekdays: rest,
    ); // Saturday
    expect(stats.currentStreak, 3);
    expect(stats.longestStreak, 3);
  });

  test('a missed training day breaks it', () {
    final h = [
      _s(DateTime(2026, 10, 12)),
      _s(DateTime(2026, 10, 16)),
    ]; // skipped Wednesday
    final stats = UserStats.from(
      h,
      today: DateTime(2026, 10, 16),
      restWeekdays: rest,
    );
    expect(stats.currentStreak, 1);
    expect(stats.longestStreak, 1);
  });

  test('today not trained yet does not break it', () {
    final h = [_s(DateTime(2026, 10, 12)), _s(DateTime(2026, 10, 14))];
    final stats = UserStats.from(
      h,
      today: DateTime(2026, 10, 16),
      restWeekdays: rest,
    ); // Friday, not trained yet
    expect(stats.currentStreak, 2);
  });

  test('without a plan it is plain consecutive days', () {
    final h = [_s(DateTime(2026, 10, 12)), _s(DateTime(2026, 10, 14))];
    final stats = UserStats.from(h, today: DateTime(2026, 10, 14));
    expect(stats.currentStreak, 1);
  });
}
