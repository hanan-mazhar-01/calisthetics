/// Where a workout quit without marking the day complete is picked up again.
///
/// [step] is the exercise step to start from (the one she was on; its
/// 10 s "First up" shows before it begins). [exercise] guards against a plan
/// that changed since: the point is only used when that step still holds
/// the same exercise. [seconds] is the time already trained and [efforts]
/// the partial-log entries written for it, so finishing the day later does
/// not count that work twice.
class ResumePoint {
  const ResumePoint({
    required this.step,
    required this.exercise,
    required this.seconds,
    this.efforts = const [],
  });

  final int step;
  final int exercise;
  final int seconds;

  /// ISO times of the partial-log entries made for the earlier attempts.
  final List<String> efforts;

  Map<String, dynamic> toJson() => {
    'step': step,
    'exercise': exercise,
    'seconds': seconds,
    'efforts': efforts,
  };

  factory ResumePoint.fromJson(Map<String, dynamic> j) => ResumePoint(
    step: j['step'] as int,
    exercise: j['exercise'] as int,
    seconds: j['seconds'] as int,
    efforts: [for (final e in (j['efforts'] as List? ?? const [])) '$e'],
  );
}
