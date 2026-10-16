import '../../user/domain/completed_session.dart';

/// The window the Activity card summarises.
enum ActivityPeriod { week, month, threeMonths }

/// One bar of the activity chart.
class ActivityBucket {
  const ActivityBucket({
    required this.label,
    required this.start,
    required this.minutes,
    required this.sessions,
    required this.isCurrent,
  });

  final String label;

  /// Date-only start of the bucket.
  final DateTime start;
  final int minutes;
  final int sessions;

  /// The bucket that contains today.
  final bool isCurrent;
}

const _dayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _monthShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Minutes trained over a period, in bars, with the same measure for the
/// period before it. Pure: built from history and "today" only.
///
///  * week: 7 daily bars Monday–Sunday of the current week; compared with the
///    previous week.
///  * month: 5 weekly bars (Monday-aligned, ending with the current week);
///    compared with the 5 weeks before.
///  * threeMonths: the current and the two previous calendar months; compared
///    with the 3 months before.
class ActivitySeries {
  const ActivitySeries({
    required this.period,
    required this.buckets,
    required this.previousMinutes,
    required this.previousSessions,
  });

  final ActivityPeriod period;
  final List<ActivityBucket> buckets;

  /// Total minutes of the equivalent previous period.
  final int previousMinutes;
  final int previousSessions;

  int get totalMinutes => buckets.fold(0, (a, b) => a + b.minutes);
  int get totalSessions => buckets.fold(0, (a, b) => a + b.sessions);
  int get maxMinutes =>
      buckets.fold(0, (a, b) => a > b.minutes ? a : b.minutes);

  /// Whether anything was trained in the previous period (otherwise a delta
  /// would compare against nothing and is hidden).
  bool get hasPrevious => previousSessions > 0;

  /// Minutes gained (or lost) against the previous period, or null with no
  /// previous data.
  int? get deltaMinutes => hasPrevious ? totalMinutes - previousMinutes : null;

  factory ActivitySeries.build(
    List<CompletedSession> history, {
    required DateTime today,
    required ActivityPeriod period,
  }) {
    final t = DateTime(today.year, today.month, today.day);
    final current = _buckets(history, t, period, 0);
    final previous = _buckets(history, t, period, 1);
    return ActivitySeries(
      period: period,
      buckets: current,
      previousMinutes: previous.fold(0, (a, b) => a + b.minutes),
      previousSessions: previous.fold(0, (a, b) => a + b.sessions),
    );
  }

  /// [shift] 0 = the current period, 1 = the one before it.
  static List<ActivityBucket> _buckets(
    List<CompletedSession> history,
    DateTime t,
    ActivityPeriod period,
    int shift,
  ) {
    final monday = DateTime(t.year, t.month, t.day - (t.weekday - 1));
    final ranges = <(String, DateTime, DateTime)>[];
    switch (period) {
      case ActivityPeriod.week:
        for (var i = 0; i < 7; i++) {
          final s = DateTime(
            monday.year,
            monday.month,
            monday.day - 7 * shift + i,
          );
          ranges.add((
            _dayInitials[i],
            s,
            DateTime(s.year, s.month, s.day + 1),
          ));
        }
      case ActivityPeriod.month:
        for (var i = 0; i < 5; i++) {
          final s = DateTime(
            monday.year,
            monday.month,
            monday.day - 7 * (4 - i) - 35 * shift,
          );
          ranges.add((
            '${_monthShort[s.month - 1]} ${s.day}',
            s,
            DateTime(s.year, s.month, s.day + 7),
          ));
        }
      case ActivityPeriod.threeMonths:
        for (var i = 0; i < 3; i++) {
          final s = DateTime(t.year, t.month - 2 + i - 3 * shift, 1);
          ranges.add((
            _monthShort[s.month - 1],
            s,
            DateTime(s.year, s.month + 1, 1),
          ));
        }
    }
    return [
      for (final (label, start, end) in ranges)
        () {
          var seconds = 0;
          var sessions = 0;
          for (final s in history) {
            final d = DateTime(
              s.finishedAt.year,
              s.finishedAt.month,
              s.finishedAt.day,
            );
            if (!d.isBefore(start) && d.isBefore(end)) {
              seconds += s.durationSeconds;
              sessions++;
            }
          }
          return ActivityBucket(
            label: label,
            start: start,
            minutes: (seconds / 60).round(),
            sessions: sessions,
            isCurrent: !t.isBefore(start) && t.isBefore(end),
          );
        }(),
    ];
  }
}
