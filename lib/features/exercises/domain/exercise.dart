/// Difficulty of an exercise, as labelled in the exercise guide.
enum ExerciseLevel {
  beginner('Beginner'),
  begInt('Beginner–Intermediate'),
  intermediate('Intermediate'),
  intAdv('Intermediate–Advanced'),
  advanced('Advanced');

  const ExerciseLevel(this.label);
  final String label;
}

class ExerciseSection {
  const ExerciseSection({required this.id, required this.title});
  final String id;
  final String title;
}

/// One entry of the 115-exercise master list. 17 entries repeat another
/// entry's movement: they carry the same [videoNumber]/[videoFile] and the
/// same filming details, so each of the 98 videos exists exactly once.
class Exercise {
  const Exercise({
    required this.number,
    required this.name,
    required this.level,
    required this.sectionId,
    required this.equipment,
    required this.purpose,
    required this.videoNumber,
    required this.videoFile,
    this.startingPosition,
    this.steps = const [],
    this.breathing,
    this.cues,
    this.mistakes,
    this.safety,
    this.easier,
    this.harder,
  });

  /// 1–115, the position in the master list. Stable; used as the id.
  final int number;
  final String name;
  final ExerciseLevel level;
  final String sectionId;
  final String equipment;
  final String purpose;

  /// Number of the entry whose video this exercise uses (itself unless it is a repeat).
  final int videoNumber;

  /// Canonical file name of the video, e.g. `calesthetics_001_wall_push_up_beginner_v1.mp4`.
  final String videoFile;

  final String? startingPosition;
  final List<String> steps;
  final String? breathing;
  final String? cues;
  final String? mistakes;
  final String? safety;
  final String? easier;
  final String? harder;

  String get id => 'ex-${number.toString().padLeft(3, '0')}';
  bool get sharesVideo => videoNumber != number;
}
