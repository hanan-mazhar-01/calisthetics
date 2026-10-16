import '../../plans/domain/plan_builder.dart';

enum StepKind { warmUp, set, coolDown }

enum Side { left, right }

/// One thing the user does between rests: a warm-up/cool-down drill, or a
/// single set (or one side of a set) of a main exercise.
class WorkoutStep {
  const WorkoutStep({
    required this.exerciseNumber,
    required this.kind,
    this.itemIndex = -1,
    this.setNumber = 1,
    this.totalSets = 1,
    this.side,
    this.reps,
    this.seconds,
  });

  final int exerciseNumber;
  final StepKind kind;

  /// Index into `BuiltSession.items`; -1 for drills.
  final int itemIndex;
  final int setNumber;
  final int totalSets;
  final Side? side;

  /// Target reps (rep exercises) — the user taps Done.
  final int? reps;

  /// Countdown length (holds and timed drills).
  final int? seconds;

  bool get isDrill => kind != StepKind.set;
  bool get isTimed => seconds != null;

  /// Last step of this exercise (last set, and last side if per-side).
  bool get endsExercise =>
      kind == StepKind.set &&
      setNumber == totalSets &&
      (side == null || side == Side.right);
}

/// Length of a timed set for exercises planned in reps.
const timedSetSeconds = PlanBuilder.drillSeconds;

/// Flattens a [BuiltSession] into the ordered list of steps the player walks.
/// Per-side exercises become two consecutive steps (left, then right) per set.
List<WorkoutStep> buildSteps(
  BuiltSession session, {
  int drillSeconds = PlanBuilder.drillSeconds,
}) {
  final steps = <WorkoutStep>[
    for (final n in session.warmUp)
      WorkoutStep(
        exerciseNumber: n,
        kind: StepKind.warmUp,
        seconds: drillSeconds,
      ),
  ];
  for (var i = 0; i < session.items.length; i++) {
    final item = session.items[i];
    for (var s = 1; s <= item.sets; s++) {
      for (final side in item.perSide ? Side.values : const [null]) {
        steps.add(
          WorkoutStep(
            exerciseNumber: item.exerciseNumber,
            kind: StepKind.set,
            itemIndex: i,
            setNumber: s,
            totalSets: item.sets,
            side: side,
            // Every main exercise is a timed set, like the warm-up drills.
            seconds: item.holdSeconds ?? timedSetSeconds,
          ),
        );
      }
    }
  }
  for (final n in session.coolDown) {
    steps.add(
      WorkoutStep(
        exerciseNumber: n,
        kind: StepKind.coolDown,
        seconds: drillSeconds,
      ),
    );
  }
  return steps;
}
