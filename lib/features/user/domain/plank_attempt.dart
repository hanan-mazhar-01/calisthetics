/// One timed plank hold. Kept so the Progress screen can draw a real trend.
class PlankAttempt {
  const PlankAttempt({required this.at, required this.seconds});

  final DateTime at;
  final int seconds;

  Map<String, dynamic> toJson() => {
    'at': at.toIso8601String(),
    'seconds': seconds,
  };

  factory PlankAttempt.fromJson(Map<String, dynamic> j) => PlankAttempt(
    at: DateTime.parse(j['at'] as String),
    seconds: j['seconds'] as int,
  );
}
