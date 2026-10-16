enum Effort { easy, justRight, hard }

/// One finished workout, as stored in history.
class CompletedSession {
  const CompletedSession({
    required this.finishedAt,
    required this.templateId,
    required this.sessionName,
    required this.durationSeconds,
    required this.exerciseNumbers,
    this.efforts = const {},
  });

  /// Template id of activities she logged by hand rather than finishing a
  /// plan workout.
  static const manualTemplateId = 'manual';

  bool get isManual => templateId == manualTemplateId;

  final DateTime finishedAt;
  final String templateId;
  final String sessionName;
  final int durationSeconds;
  final List<int> exerciseNumbers;

  /// Per-exercise "how did it feel" answers, keyed by exercise number.
  final Map<int, Effort> efforts;

  Map<String, dynamic> toJson() => {
    'finishedAt': finishedAt.toIso8601String(),
    'templateId': templateId,
    'sessionName': sessionName,
    'durationSeconds': durationSeconds,
    'exerciseNumbers': exerciseNumbers,
    'efforts': {for (final e in efforts.entries) '${e.key}': e.value.name},
  };

  factory CompletedSession.fromJson(Map<String, dynamic> j) => CompletedSession(
    finishedAt: DateTime.parse(j['finishedAt'] as String),
    templateId: j['templateId'] as String,
    sessionName: j['sessionName'] as String,
    durationSeconds: j['durationSeconds'] as int,
    exerciseNumbers: (j['exerciseNumbers'] as List).cast<int>(),
    efforts: {
      for (final e in ((j['efforts'] as Map?) ?? const {}).entries)
        int.parse(e.key as String): Effort.values.firstWhere(
          (v) => v.name == e.value,
          orElse: () => Effort.justRight,
        ),
    },
  );
}
