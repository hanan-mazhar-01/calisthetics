import '../../user/domain/completed_session.dart';
import 'workout_steps.dart';

/// `preview` is the opening "First up"; `rest` is recovery (it also previews
/// what is next); `rating` asks Easy / Just right / Hard after an exercise.
enum WorkoutPhase { preview, work, rest, rating, done }

/// Seconds of the opening "First up" countdown.
const workoutPreviewSeconds = 10;

/// Default rest between exercises and sets; "+10 s" lets the user add more.
const workoutRestSeconds = 10;

/// Added by the "+10 s" button on preview/rest.
const workoutExtendSeconds = 10;

/// Immutable player state with pure transitions (no timers, no Flutter).
///
/// [index] is the step being done, or — during `preview`/`rest` — the step
/// that is coming up. During `rating` it is the step just finished.
class WorkoutState {
  const WorkoutState({
    required this.steps,
    required this.restSeconds,
    this.index = 0,
    this.phase = WorkoutPhase.preview,
    this.efforts = const {},
    this.paused = false,
    this.skipped = const {},
    this.demo = false,
  });

  factory WorkoutState.start(
    List<WorkoutStep> steps, {
    int restSeconds = workoutRestSeconds,
    bool demo = false,
  }) => WorkoutState(
    steps: steps,
    restSeconds: restSeconds,
    demo: demo,
    phase: steps.isEmpty
        ? WorkoutPhase.done
        : demo
        ? WorkoutPhase.work
        : WorkoutPhase.preview,
  );

  /// A try-out of a single exercise: no first-up, no rating, then done.
  final bool demo;

  final List<WorkoutStep> steps;
  final int restSeconds;
  final int index;
  final WorkoutPhase phase;
  final Map<int, Effort> efforts;
  final bool paused;

  /// Indices of steps jumped over with "next exercise"; never counted as done.
  final Set<int> skipped;

  WorkoutStep get step => steps[index.clamp(0, steps.length - 1)];
  bool get isDone => phase == WorkoutPhase.done;
  WorkoutStep? get nextStep =>
      index + 1 < steps.length ? steps[index + 1] : null;

  /// Seconds the current phase counts down from, or null when it waits for
  /// the user (rep sets and the rating).
  int? get phaseSeconds => switch (phase) {
    WorkoutPhase.preview => workoutPreviewSeconds,
    WorkoutPhase.rest => restSeconds,
    WorkoutPhase.work => step.seconds,
    _ => null,
  };

  /// True for the "First up" announcement: the opening preview, or the
  /// break before a different exercise (as opposed to a rest between sets).
  bool get isIntro =>
      phase == WorkoutPhase.preview ||
      (phase == WorkoutPhase.rest &&
          index > 0 &&
          steps[index - 1].exerciseNumber != step.exerciseNumber);

  /// Exercise whose video should be on screen: the upcoming one while
  /// previewing/resting, otherwise the current one.
  int get displayExercise => step.exerciseNumber;

  /// Main-exercise numbers fully finished so far, in order, without repeats.
  List<int> get completedExercises {
    final out = <int>[];
    final last = phase == WorkoutPhase.rating || phase == WorkoutPhase.done
        ? index
        : index - 1;
    for (var i = 0; i <= last && i < steps.length; i++) {
      final s = steps[i];
      if (s.endsExercise &&
          !skipped.contains(i) &&
          !out.contains(s.exerciseNumber)) {
        out.add(s.exerciseNumber);
      }
    }
    return out;
  }

  /// Fraction of steps finished (for the progress bar).
  double get progress {
    if (steps.isEmpty || isDone) return 1;
    final finished = phase == WorkoutPhase.rating ? index + 1 : index;
    return finished / steps.length;
  }

  // ── Transitions ───────────────────────────────────────────────────

  WorkoutState copyWith({
    int? index,
    WorkoutPhase? phase,
    Map<int, Effort>? efforts,
    bool? paused,
    Set<int>? skipped,
  }) => WorkoutState(
    steps: steps,
    restSeconds: restSeconds,
    index: index ?? this.index,
    phase: phase ?? this.phase,
    efforts: efforts ?? this.efforts,
    paused: paused ?? this.paused,
    skipped: skipped ?? this.skipped,
    demo: demo,
  );

  /// Preview or rest is over (timer hit 0 or Skip): start the step at [index].
  WorkoutState startWork() =>
      phase == WorkoutPhase.preview || phase == WorkoutPhase.rest
      ? copyWith(phase: WorkoutPhase.work, paused: false)
      : this;

  /// The current step finished (Done tapped or countdown hit 0 / Skip).
  /// Asks for a rating after a main exercise, otherwise moves on.
  WorkoutState finishStep() {
    if (phase != WorkoutPhase.work) return this;
    if (demo) return copyWith(phase: WorkoutPhase.done);
    if (step.endsExercise) return copyWith(phase: WorkoutPhase.rating);
    return _advance();
  }

  /// Records the answer (null = skipped) and moves on.
  WorkoutState rate(Effort? effort) {
    if (phase != WorkoutPhase.rating) return this;
    final next = effort == null
        ? efforts
        : {...efforts, step.exerciseNumber: effort};
    return copyWith(efforts: next)._advance();
  }

  WorkoutState _advance() {
    final next = nextStep;
    if (next == null) return copyWith(phase: WorkoutPhase.done);
    final cur = step;
    final sameSet =
        cur.kind == StepKind.set &&
        next.kind == StepKind.set &&
        next.itemIndex == cur.itemIndex &&
        next.setNumber == cur.setNumber; // left side → right side
    return copyWith(
      index: index + 1,
      phase: sameSet ? WorkoutPhase.work : WorkoutPhase.rest,
    );
  }

  /// Back to the previous step (no rest in between). No-op on the first step
  /// and while rating.
  WorkoutState previous() {
    if (index == 0 || phase == WorkoutPhase.rating || isDone) return this;
    return copyWith(index: index - 1, phase: WorkoutPhase.work, paused: false);
  }

  /// Jumps past the rest of the current exercise (all remaining sets/sides).
  /// The skipped steps do not count as completed.
  WorkoutState skipExercise() {
    if (phase == WorkoutPhase.rating || isDone) return this;
    final cur = step;
    var j = index + 1;
    while (cur.kind == StepKind.set &&
        j < steps.length &&
        steps[j].kind == StepKind.set &&
        steps[j].itemIndex == cur.itemIndex) {
      j++;
    }
    final skip = {...skipped, for (var i = index; i < j; i++) i};
    if (j >= steps.length) {
      return copyWith(phase: WorkoutPhase.done, skipped: skip);
    }
    return copyWith(
      index: j,
      skipped: skip,
      paused: false,
      phase: WorkoutPhase.rest,
    );
  }

  WorkoutState withPaused(bool value) => copyWith(paused: value);
}
