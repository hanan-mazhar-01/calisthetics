import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../exercises/domain/exercise_lookup.dart';
import '../../../user/domain/completed_session.dart';
import '../../../user/domain/partial_effort.dart';
import '../../../user/domain/resume_point.dart';
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

  /// Set when this run picks up a workout quit earlier: the time already
  /// trained and the exercises already done, so none of it counts twice.
  ResumePoint? _resumed;
  Set<int> _doneBefore = const {};

  /// True while the exercise video on screen is still loading: the
  /// countdown waits, so no seconds are lost to a loading screen. A slow or
  /// failed load never freezes the workout: after [_maxHold] it moves on.
  bool _videoLoading = false;
  int _heldTicks = 0;
  static const _maxHold = 12;

  /// Called by the player's video when it starts or finishes loading.
  void setVideoLoading(bool loading) {
    _videoLoading = loading;
    if (!loading) _heldTicks = 0;
  }

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
    final steps = buildSteps(request.session);
    final restSeconds = rest is num && rest > 0
        ? rest.toInt()
        : workoutRestSeconds;
    // A day left half-done starts again from the exercise it was left on,
    // as long as the plan still has that exercise there.
    final key = request.progressKey;
    var saved = key == null || request.demo
        ? null
        : ref.read(partialProgressProvider.notifier).resumePoint(key);
    final percent = key == null ? null : ref.read(partialProgressProvider)[key];
    if (saved == null && percent != null && percent > 0 && steps.isNotEmpty) {
      // Left before exact positions were kept: the step is read back from
      // the percent (the first step whose share rounds down to it).
      final step = (percent * steps.length / 100).ceil();
      if (step > 0 && step < steps.length) {
        saved = ResumePoint(
          step: step,
          exercise: steps[step].exerciseNumber,
          seconds: 0,
        );
      }
    }
    if (saved != null &&
        saved.step > 0 &&
        saved.step < steps.length &&
        steps[saved.step].exerciseNumber == saved.exercise) {
      _resumed = saved;
      _doneBefore = WorkoutState.start(
        steps,
        restSeconds: restSeconds,
        startIndex: saved.step,
      ).completedExercises.toSet();
    }
    final initial = WorkoutState.start(
      steps,
      restSeconds: restSeconds,
      demo: request.demo,
      startIndex: _resumed?.step ?? 0,
    );
    countdown.value = initial.phaseSeconds ?? 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    return initial;
  }

  void _tick() {
    final s = state;
    if (s.paused || s.isDone) return;
    if (_videoLoading && s.phaseSeconds != null && _heldTicks < _maxHold) {
      _heldTicks++;
      return;
    }
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
    // though not to her workout count or streak. Exercises done in an
    // earlier attempt were already counted then.
    final done = state.completedExercises
        .where((e) => !_doneBefore.contains(e))
        .length;
    final efforts = [...?_resumed?.efforts];
    if (_elapsed >= 5 || done > 0) {
      final at = ref.read(clockProvider)();
      await ref
          .read(partialLogProvider.notifier)
          .add(PartialEffort(at: at, seconds: _elapsed, exercises: done));
      efforts.add(at.toIso8601String());
    }
    final percent = percentDone;
    if (key != null && percent > 0) {
      // Pick up on the exercise she was on (after a rating: the next one).
      final last = state.steps.length - 1;
      final step =
          (state.phase == WorkoutPhase.rating ? state.index + 1 : state.index)
              .clamp(0, last);
      await ref
          .read(partialProgressProvider.notifier)
          .set(
            key,
            percent,
            resume: ResumePoint(
              step: step,
              exercise: state.steps[step].exerciseNumber,
              seconds: (_resumed?.seconds ?? 0) + _elapsed,
              efforts: efforts,
            ),
          );
    }
  }

  Future<void> _save(List<int> exercises, Map<int, Effort> efforts) async {
    if (_saved != null) return;
    final earlier = _resumed;
    final session = CompletedSession(
      finishedAt: ref.read(clockProvider)(),
      templateId: request.templateId,
      sessionName: request.session.name,
      // The whole day: time from the earlier attempts plus this one.
      durationSeconds: _elapsed + (earlier?.seconds ?? 0),
      exerciseNumbers: exercises,
      efforts: efforts,
    );
    _saved = session;
    await ref.read(historyProvider.notifier).add(session);
    // The session now holds the work logged for the earlier attempts.
    if (earlier != null) {
      await ref.read(partialLogProvider.notifier).removeAt(earlier.efforts);
    }
  }
}
