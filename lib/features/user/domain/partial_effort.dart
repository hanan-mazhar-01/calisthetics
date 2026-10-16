/// Time and exercises from a workout she left early without marking the day
/// complete. It adds to her minutes and exercise totals (the work really
/// happened) but never to her workout count, streak or plan days.
class PartialEffort {
  const PartialEffort({
    required this.at,
    required this.seconds,
    required this.exercises,
  });

  final DateTime at;
  final int seconds;
  final int exercises;

  Map<String, dynamic> toJson() => {
    'at': at.toIso8601String(),
    'seconds': seconds,
    'exercises': exercises,
  };

  factory PartialEffort.fromJson(Map<String, dynamic> j) => PartialEffort(
    at: DateTime.parse(j['at'] as String),
    seconds: j['seconds'] as int,
    exercises: j['exercises'] as int,
  );
}
