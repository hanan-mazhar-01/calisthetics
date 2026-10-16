/// TODO(owner): the free monthly Coach message allowance is not decided yet.
const freeMonthlyCoachMessages = 10;

/// Messages sent in one calendar month. Pure and JSON-serialisable so it can
/// live in settings.
class CoachQuota {
  const CoachQuota({required this.monthKey, this.used = 0});

  /// "2026-10".
  final String monthKey;
  final int used;

  static String keyFor(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  factory CoachQuota.empty(DateTime now) => CoachQuota(monthKey: keyFor(now));

  /// Usage that counts in the month of [now] (a new month starts at zero).
  int usedIn(DateTime now) => monthKey == keyFor(now) ? used : 0;

  int remaining(DateTime now, {int limit = freeMonthlyCoachMessages}) =>
      (limit - usedIn(now)).clamp(0, limit);

  bool canSend(
    DateTime now, {
    required bool isPremium,
    int limit = freeMonthlyCoachMessages,
  }) => isPremium || remaining(now, limit: limit) > 0;

  CoachQuota recordSend(DateTime now) =>
      CoachQuota(monthKey: keyFor(now), used: usedIn(now) + 1);

  Map<String, dynamic> toJson() => {'month': monthKey, 'used': used};

  factory CoachQuota.fromJson(Object? raw, DateTime now) {
    if (raw is Map && raw['month'] is String && raw['used'] is int) {
      return CoachQuota(
        monthKey: raw['month'] as String,
        used: raw['used'] as int,
      );
    }
    return CoachQuota.empty(now);
  }
}
