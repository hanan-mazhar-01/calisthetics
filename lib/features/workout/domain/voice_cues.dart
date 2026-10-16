import 'workout_steps.dart';

enum VoiceCueMode {
  off,
  brief,
  detailed;

  static VoiceCueMode parse(Object? raw) => VoiceCueMode.values.firstWhere(
    (m) => m.name == raw,
    orElse: () => VoiceCueMode.brief,
  );
}

enum VoiceCueKind { exerciseStart, halfway, rest }

class VoiceCue {
  const VoiceCue(this.kind, this.text);
  final VoiceCueKind kind;
  final String text;
}

/// Speaks cues. No text-to-speech package is installed yet, so the only
/// implementation is [SilentVoiceCuePlayer]; a real one slots in here.
abstract interface class VoiceCuePlayer {
  void play(VoiceCue cue);
}

class SilentVoiceCuePlayer implements VoiceCuePlayer {
  const SilentVoiceCuePlayer();
  @override
  void play(VoiceCue cue) {}
}

/// Pure cue schedule: which cue (if any) belongs to which moment.
class VoiceCuePlanner {
  const VoiceCuePlanner({required this.mode, this.halfway = true});

  final VoiceCueMode mode;
  final bool halfway;

  /// When a work step begins. Detailed mode adds the first form cue.
  VoiceCue? onStepStart(WorkoutStep step, String name, {String? cue}) {
    if (mode == VoiceCueMode.off) return null;
    final side = switch (step.side) {
      Side.left => ', left side',
      Side.right => ', right side',
      null => '',
    };
    final base = '$name$side';
    final text = mode == VoiceCueMode.detailed && cue != null && cue.isNotEmpty
        ? '$base. $cue'
        : base;
    return VoiceCue(VoiceCueKind.exerciseStart, text);
  }

  /// Second at which the halfway prompt fires for a timed step, or null.
  int? halfwaySecond(WorkoutStep step) {
    if (mode == VoiceCueMode.off || !halfway) return null;
    final s = step.seconds;
    if (s == null || s < 10) return null;
    return s ~/ 2; // remaining seconds when it fires
  }

  VoiceCue? onHalfway() => mode == VoiceCueMode.off || !halfway
      ? null
      : const VoiceCue(VoiceCueKind.halfway, 'Halfway there');

  VoiceCue? onRest(int seconds) => mode == VoiceCueMode.off
      ? null
      : VoiceCue(VoiceCueKind.rest, 'Rest for $seconds seconds');
}
