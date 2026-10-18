import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/features/plans/domain/plan_builder.dart';
import 'package:calisthenics/features/user/domain/resume_point.dart';
import 'package:calisthenics/features/user/presentation/providers/user_providers.dart';
import 'package:calisthenics/features/workout/domain/workout_request.dart';
import 'package:calisthenics/features/workout/domain/workout_state.dart';
import 'package:calisthenics/features/workout/domain/workout_steps.dart';
import 'package:calisthenics/features/workout/presentation/providers/workout_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'foundation-full-body|2026-10-14';

// Steps: 0 warm-up 90, 1 warm-up 91, 2 main exercise 1, 3 cool-down 95.
const _request = WorkoutRequest(
  templateId: 'foundation-full-body',
  progressKey: _key,
  session: BuiltSession(
    name: 'Quick',
    warmUp: [90, 91],
    items: [BuiltItem(exerciseNumber: 1, sets: 1, reps: 8)],
    coolDown: [95],
    estimatedMinutes: 2,
  ),
);

late SharedPreferences _prefs;

/// A fresh app session on the phone's saved data: what one run saved is what
/// the next one finds.
Future<ProviderContainer> _container({bool fresh = true}) async {
  if (fresh) {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  }
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(_prefs)],
  );
  addTearDown(c.dispose);
  return c;
}

/// Opens the player the way the screen does; closing the returned listener
/// lets the controller go (the next open starts a fresh run).
({WorkoutController ctl, ProviderSubscription<WorkoutState> sub}) _open(
  ProviderContainer c,
) {
  final sub = c.listen(workoutControllerProvider(_request), (_, _) {});
  return (ctl: c.read(workoutControllerProvider(_request).notifier), sub: sub);
}

void main() {
  test('a state can open on a later step', () {
    final steps = buildSteps(_request.session);
    final s = WorkoutState.start(steps, startIndex: 2);
    expect(s.index, 2);
    expect(s.phase, WorkoutPhase.preview);
    expect(s.progress, 0.5);
    expect(WorkoutState.start(steps, startIndex: 99).index, steps.length - 1);
    expect(WorkoutState.start(steps).index, 0);
  });

  testWidgets('quitting remembers the exercise, the next start resumes there', (
    t,
  ) async {
    final c = await _container();
    var run = _open(c);
    expect(run.ctl.state.index, 0);

    run.ctl.skipRest(); // first up -> warm-up 90
    await t.pump(const Duration(seconds: 6));
    run.ctl.finishStep(); // -> rest before warm-up 91
    run.ctl.skipRest(); // -> warm-up 91 running
    expect(run.ctl.state.index, 1);
    await run.ctl.quit(markComplete: false);
    expect(c.read(partialProgressProvider)[_key], 25);
    final saved = c.read(partialProgressProvider.notifier).resumePoint(_key)!;
    expect(saved.step, 1);
    expect(saved.exercise, 91);
    run.sub.close();
    c.dispose(); // the app is closed or the player left

    // Back on the plan: Start again opens on warm-up 91, not on the first.
    final c2 = await _container(fresh: false);
    run = _open(c2);
    expect(run.ctl.state.index, 1);
    expect(run.ctl.state.phase, WorkoutPhase.preview);
    expect(run.ctl.state.step.exerciseNumber, 91);
    run.sub.close();
    c2.dispose();
  });

  testWidgets('finishing after a resume counts the whole day once', (t) async {
    final c = await _container();
    var run = _open(c);
    run.ctl.skipRest();
    await t.pump(const Duration(seconds: 6));
    run.ctl.finishStep();
    run.ctl.skipRest();
    await run.ctl.quit(markComplete: false);
    final firstSeconds = c.read(partialLogProvider).single.seconds;
    expect(firstSeconds, greaterThanOrEqualTo(5));
    run.sub.close();
    c.dispose();

    final c2 = await _container(fresh: false);
    run = _open(c2);
    expect(run.ctl.state.index, 1);
    run.ctl.skipRest(); // warm-up 91
    await t.pump(const Duration(seconds: 3));
    run.ctl.finishStep();
    run.ctl.skipRest(); // main exercise 1
    run.ctl.finishStep(); // -> rating
    run.ctl.rate(null);
    run.ctl.skipRest(); // cool-down 95
    run.ctl.finishStep(); // last step -> done
    await t.pump(const Duration(milliseconds: 100));

    final history = c2.read(historyProvider);
    expect(history, hasLength(1));
    // Time from both attempts, the main exercise once.
    expect(history.single.durationSeconds, greaterThan(firstSeconds));
    expect(history.single.exerciseNumbers, [1]);
    // The first attempt's partial entry is folded into the session.
    expect(c2.read(partialLogProvider), isEmpty);
    expect(c2.read(partialProgressProvider), isEmpty);
    expect(c2.read(partialProgressProvider.notifier).resumePoint(_key), isNull);
    run.sub.close();
    c2.dispose();
  });

  testWidgets('an older half-done day resumes from its percent', (t) async {
    final c = await _container();
    // Saved before exact positions were kept: only "50% done".
    await c.read(partialProgressProvider.notifier).set(_key, 50);
    final run = _open(c);
    expect(run.ctl.state.index, 2); // 2 of the 4 steps were done
    expect(run.ctl.state.phase, WorkoutPhase.preview);
    run.sub.close();
    c.dispose();
  });

  testWidgets('a plan that changed does not resume on the wrong exercise', (
    t,
  ) async {
    final c = await _container();
    await c
        .read(partialProgressProvider.notifier)
        .set(
          _key,
          25,
          resume: const ResumePoint(step: 1, exercise: 999, seconds: 30),
        );
    final run = _open(c);
    expect(run.ctl.state.index, 0);
    run.sub.close();
    c.dispose();
  });

  testWidgets('starting over a day clears where it was left', (t) async {
    final c = await _container();
    await c
        .read(partialProgressProvider.notifier)
        .set(
          _key,
          40,
          resume: const ResumePoint(step: 2, exercise: 1, seconds: 60),
        );
    await c
        .read(partialProgressProvider.notifier)
        .clearWhere((k) => k.startsWith('foundation-full-body|'));
    expect(c.read(partialProgressProvider), isEmpty);
    expect(c.read(partialProgressProvider.notifier).resumePoint(_key), isNull);
  });
}
