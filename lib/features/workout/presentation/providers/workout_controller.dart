import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../exercises/domain/exercise_lookup.dart';
import '../../../user/domain/completed_session.dart';
import '../../../user/domain/partial_effort.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../domain/voice_cues.dart';
import '../../domain/workout_request.dart';
import '../../domain/workout_state.dart';
import '../../domain/workout_steps.dart';

final voiceCuePlayerProvider = Provider<VoiceCuePlayer>(
  (ref) => const SilentVoiceCuePlayer(),
);

final workoutControllerProvider = NotifierProvider.autoDispose
    .family<WorkoutController, WorkoutState, WorkoutRequest>(
      WorkoutController.new,
    );

/// Runs a session: owns the 1 s ticker and applies the pure transitions of
/// [WorkoutState]. The countdown lives in [countdown], a ValueNotifier, so a
/// tick rebuilds only the timer widget — never the screen.
class WorkoutController extends Notifier<WorkoutState> {
  WorkoutController(this.request);

  final WorkoutRequest request;

  final countdown = ValueNotifier<int>(0);
  Timer? _timer;
  int _elapsed = 0;
  CompletedSession? _saved;

  /// The session written to history (set once the workout ends or is saved).
  CompletedSession? get saved => _saved;

  VoiceCuePlanner get _planner {
    final s = ref.read(settingsProvider);
    return VoiceCuePlanner(
      mode: VoiceCueMode.parse(s['voiceCues']),
      halfway: (s['halfwayPrompt'] as bool?) ?? true,
    );
  }

  @override
  WorkoutState build() {
    ref.onDispose(() {
      _timer?.cancel();
      countdown.dispose();
    });
    final rest = ref.read(settingsProvider)['restSeconds'];
    final initial = WorkoutState.start(
      buildSteps(request.session),
      restSeconds: rest is num && rest > 0 ? rest.toInt() : workoutRestSeconds,
      demo: request.demo,
    );
    countdown.value = initial.phaseSeconds ?? 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    return initial;
  }

  void _tick() {
    final s = state;
    if (s.paused || s.isDone) return;
    _elapsed++;
    if (s.phaseSeconds == null) return; // waiting on the user
    final left = countdown.value - 1;
    countdown.value = left < 0 ? 0 : left;
    if (s.phase == WorkoutPhase.work &&
        left == _planner.halfwaySecond(s.step)) {
      _speak(_planner.onHalfway());
    }
    if (left <= 0) {
      _apply(s.phase == WorkoutPhase.work ? s.finishStep() : s.startWork());
    }
  }

  void _apply(WorkoutState next) {
    final before = state;
    state = next;
    if (next.phase != before.phase || next.index != before.index) {
      countdown.value = next.phaseSeconds ?? 0;
      _onEnter(next);
    }
  }

  void _onEnter(WorkoutState s) {
    switch (s.phase) {
      case WorkoutPhase.work:
        final ex = exerciseByNumber(s.step.exerciseNumber);
        final cue = ex.cues?.split(RegExp(r'(?<=[.!?])\s')).first;
        _speak(_planner.onStepStart(s.step, ex.name, cue: cue));
      case WorkoutPhase.rest:
        _speak(_planner.onRest(s.restSeconds));
      case WorkoutPhase.done:
        _timer?.cancel();
        if (request.demo) return; // a try-out is never saved
        unawaited(_save(s.completedExercises, s.efforts));
        final key = request.progressKey;
        if (key != null) {
          unawaited(ref.read(partialProgressProvider.notifier).clear(key));
        }
      case WorkoutPhase.preview || WorkoutPhase.rating:
    }
  }

  void _speak(VoiceCue? cue) {
    if (cue != null) ref.read(voiceCuePlayerProvider).play(cue);
  }

  // ── User actions ──────────────────────────────────────────────────

  /// Done button / Skip on a work step.
  void finishStep() => _apply(state.finishStep());

  /// Skip on preview or rest.
  void skipRest() => _apply(state.startWork());

  void extendRest() {
    if (state.phase == WorkoutPhase.rest ||
        state.phase == WorkoutPhase.preview) {
      countdown.value += workoutExtendSeconds;
    }
  }

  /// Capsule "previous": redo the step before this one.
  void previousStep() => _apply(state.previous());

  void rate(Effort? effort) => _apply(state.rate(effort));

  void setPaused(bool paused) => state = state.withPaused(paused);

  /// Percent of the workout done so far, 0-99 until it is finished.
  int get percentDone => (state.progress * 100).floor().clamp(0, 99);

  /// Quit. With [markComplete] the day counts as done (what she finished is
  /// saved to her history); otherwise only how far she got is kept, and the
  /// day stays open.
  Future<void> quit({required bool markComplete}) async {
    final key = request.progressKey;
    if (markComplete) {
      await _save(state.completedExercises, state.efforts);
      if (key != null) {
        await ref.read(partialProgressProvider.notifier).clear(key);
      }
      return;
    }
    // The work still happened: it adds to her minutes and exercise totals,
    // though not to her workout count or streak.
    final done = state.completedExercises.length;
    if (_elapsed >= 5 || done > 0) {
      await ref
          .read(partialLogProvider.notifier)
          .add(
            PartialEffort(
              at: ref.read(clockProvider)(),
              seconds: _elapsed,
              exercises: done,
            ),
          );
    }
    final percent = percentDone;
    if (key != null && percent > 0) {
      await ref.read(partialProgressProvider.notifier).set(key, percent);
    }
  }

  Future<void> _save(List<int> exercises, Map<int, Effort> efforts) async {
    if (_saved != null) return;
    final session = CompletedSession(
      finishedAt: ref.read(clockProvider)(),
      templateId: request.templateId,
      sessionName: request.session.name,
      durationSeconds: _elapsed,
      exerciseNumbers: exercises,
      efforts: efforts,
    );
    _saved = session;
    await ref.read(historyProvider.notifier).add(session);
  }
}
