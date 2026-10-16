import 'workout_steps.dart';

/// Display strings for a step. Pure, so they are unit-testable.
extension WorkoutStepLabels on WorkoutStep {
  /// "12 reps", "30 s hold" or "30 s".
  String get targetLabel {
    if (reps != null) return '$reps reps';
    final s = seconds ?? 0;
    return kind == StepKind.set ? '$s s hold' : '$s s';
  }

  /// "Set 2 of 3 · Left side", or "Warm-up" / "Cool-down" for drills.
  String get progressLabel => switch (kind) {
    StepKind.warmUp => 'Warm-up',
    StepKind.coolDown => 'Cool-down',
    StepKind.set => [
      if (totalSets > 1) 'Set $setNumber of $totalSets',
      if (side == Side.left) 'Left side',
      if (side == Side.right) 'Right side',
    ].join(' · '),
  };
}

/// "0:45", "1:05".
String formatClock(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// "00:45", "01:05" — the player's big timer.
String formatTimer(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  return '${(s ~/ 60).toString().padLeft(2, '0')}:'
      '${(s % 60).toString().padLeft(2, '0')}';
}
