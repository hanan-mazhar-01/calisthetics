/// A single bodyweight movement. `mediaPrompt` is the asset brief for its
/// thumbnail/video slot until real media is wired in.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.mediaPrompt,
    this.reps = '30s',
  });

  final String id;
  final String name;
  final String mediaPrompt;

  /// Workout-player rep/time scheme shown on exercise bars ("×8", "30s").
  final String reps;
}

/// The 6-exercise set used throughout onboarding's "plan creation" preview
/// and the workout player — the actual program's exercise pool for now.
const coreExercises = [
  Exercise(
    id: 'incline-pushup',
    name: 'Incline Push-Up',
    mediaPrompt: 'Incline Push-Up',
    reps: '×8',
  ),
  Exercise(
    id: 'forearm-plank',
    name: 'Forearm Plank',
    mediaPrompt: 'Forearm Plank',
    reps: '30s',
  ),
  Exercise(
    id: 'knee-pushup',
    name: 'Knee Push-Up',
    mediaPrompt: 'Knee Push-Up',
    reps: '×8',
  ),
  Exercise(
    id: 'glute-bridge',
    name: 'Glute Bridge',
    mediaPrompt: 'Glute Bridge',
    reps: '×12',
  ),
  Exercise(
    id: 'pike-hold',
    name: 'Pike Hold',
    mediaPrompt: 'Pike Hold',
    reps: '20s',
  ),
  Exercise(
    id: 'hollow-hold',
    name: 'Hollow Body Hold',
    mediaPrompt: 'Hollow Body Hold',
    reps: '20s',
  ),
];
