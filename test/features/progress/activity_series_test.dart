import 'package:calisthenics/features/progress/domain/activity_series.dart';
import 'package:calisthenics/features/user/domain/completed_session.dart';
import 'package:flutter_test/flutter_test.dart';

CompletedSession _s(DateTime at, int minutes) => CompletedSession(
  finishedAt: at,
  templateId: 'x',
  sessionName: 'S',
  durationSeconds: minutes * 60,
  exerciseNumbers: const [1],
);

void main() {
  // Wednesday 14 Oct 2026.
  final today = DateTime(2026, 10, 14);

  ActivitySeries build(List<CompletedSession> h, ActivityPeriod p) =>
      ActivitySeries.build(h, today: today, period: p);

  group('week', () {
    test('sums minutes per weekday inside the current Mon-Sun week', () {
      final s = build([
        _s(DateTime(2026, 10, 12, 9), 15), // Mon
        _s(DateTime(2026, 10, 12, 18), 10), // Mon again
        _s(DateTime(2026, 10, 14, 8), 20), // Wed
        _s(DateTime(2026, 10, 11, 8), 30), // previous Sunday: excluded
        _s(DateTime(2026, 10, 19, 8), 30), // next Monday: excluded
      ], ActivityPeriod.week);
      expect([for (final b in s.buckets) b.minutes], [25, 0, 20, 0, 0, 0, 0]);
      expect(s.buckets.indexWhere((b) => b.isCurrent), 2);
      expect(s.totalMinutes, 45);
      expect(s.totalSessions, 3);
      expect(s.maxMinutes, 25);
      expect(s.buckets.first.label, 'M');
    });

    test('delta compares with the previous week and hides without data', () {
      final h = [
        _s(DateTime(2026, 10, 12), 30),
        _s(DateTime(2026, 10, 7), 18), // previous Wed
      ];
      final s = build(h, ActivityPeriod.week);
      expect(s.previousMinutes, 18);
      expect(s.deltaMinutes, 12);
      expect(
        build([
          _s(DateTime(2026, 10, 12), 30),
        ], ActivityPeriod.week).deltaMinutes,
        isNull,
      );
    });

    test('empty history is all zeros with no delta', () {
      final s = build(const [], ActivityPeriod.week);
      expect(s.totalMinutes, 0);
      expect(s.maxMinutes, 0);
      expect(s.deltaMinutes, isNull);
    });
  });

  group('month', () {
    test('five Monday-aligned weekly buckets ending with this week', () {
      final s = build([
        _s(DateTime(2026, 10, 13), 10), // this week
        _s(DateTime(2026, 10, 8), 20), // week of 5 Oct
        _s(DateTime(2026, 9, 15), 40), // week of 14 Sep: 4th bucket back? no
        _s(DateTime(2026, 9, 14), 5), // Monday 14 Sep = first bucket
        _s(DateTime(2026, 9, 13), 99), // Sunday before: previous period
      ], ActivityPeriod.month);
      expect(s.buckets.length, 5);
      expect(s.buckets.first.start, DateTime(2026, 9, 14));
      expect(s.buckets.last.start, DateTime(2026, 10, 12));
      expect([for (final b in s.buckets) b.minutes], [45, 0, 0, 20, 10]);
      expect(s.buckets.last.isCurrent, isTrue);
      expect(s.buckets.first.label, 'Sep 14');
      expect(s.previousMinutes, 99);
      expect(s.deltaMinutes, 75 - 99);
    });
  });

  group('three months', () {
    test('current and two previous calendar months, across a year end', () {
      final s = ActivitySeries.build(
        [
          _s(DateTime(2026, 1, 5), 10),
          _s(DateTime(2025, 12, 31), 20),
          _s(DateTime(2025, 11, 1), 30),
          _s(DateTime(2025, 10, 31), 7), // previous period
        ],
        today: DateTime(2026, 1, 20),
        period: ActivityPeriod.threeMonths,
      );
      expect([for (final b in s.buckets) b.label], ['Nov', 'Dec', 'Jan']);
      expect([for (final b in s.buckets) b.minutes], [30, 20, 10]);
      expect(s.totalMinutes, 60);
      expect(s.totalSessions, 3);
      expect(s.previousMinutes, 7);
      expect(s.deltaMinutes, 53);
      expect(s.buckets.last.isCurrent, isTrue);
    });
  });
}
