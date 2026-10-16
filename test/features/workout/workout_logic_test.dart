import 'package:calisthenics/features/plans/domain/plan_builder.dart';
import 'package:calisthenics/features/user/domain/completed_session.dart';
import 'package:calisthenics/features/workout/domain/progression_feedback.dart';
import 'package:calisthenics/features/workout/domain/step_labels.dart';
import 'package:calisthenics/features/workout/domain/voice_cues.dart';
import 'package:calisthenics/features/workout/domain/workout_state.dart';
import 'package:calisthenics/features/workout/domain/workout_steps.dart';
import 'package:flutter_test/flutter_test.dart';

BuiltSession session({
  List<int> warmUp = const [],
  List<BuiltItem> items = const [],
  List<int> coolDown = const [],
}) => BuiltSession(
  name: 'Test',
  warmUp: warmUp,
  items: items,
  coolDown: coolDown,
  estimatedMinutes: 10,
);

void main() {
  group('buildSteps', () {
    test('orders warm-up, sets, cool-down; drills are timed', () {
      final steps = buildSteps(
        session(
          warmUp: [90, 91],
          items: const [BuiltItem(exerciseNumber: 1, sets: 2, reps: 10)],
          coolDown: [95],
        ),
      );
      expect(steps.map((s) => s.kind), [
        StepKind.warmUp,
        StepKind.warmUp,
        StepKind.set,
        StepKind.set,
        StepKind.coolDown,
      ]);
      expect(steps.first.seconds, PlanBuilder.drillSeconds);
      expect(steps[2].reps, isNull); // rep exercises run as timed sets
      expect(steps[2].seconds, timedSetSeconds);
      expect(steps[3].setNumber, 2);
    });

    test('hold exercises are timed, per-side doubles each set', () {
      final steps = buildSteps(
        session(
          items: const [
            BuiltItem(
              exerciseNumber: 5,
              sets: 2,
              holdSeconds: 20,
              perSide: true,
            ),
          ],
        ),
      );
      expect(steps.length, 4);
      expect(steps.map((s) => s.side), [
        Side.left,
        Side.right,
        Side.left,
        Side.right,
      ]);
      expect(steps.every((s) => s.seconds == 20 && s.reps == null), isTrue);
      expect(steps.map((s) => s.endsExercise), [false, false, false, true]);
    });
  });

  group('WorkoutState transitions', () {
    WorkoutState start(BuiltSession s) =>
        WorkoutState.start(buildSteps(s), restSeconds: 30);

    test('starts in preview and exposes countdown lengths', () {
      final s = start(
        session(items: const [BuiltItem(exerciseNumber: 1, sets: 1, reps: 8)]),
      );
      expect(s.phase, WorkoutPhase.preview);
      expect(s.phaseSeconds, workoutPreviewSeconds);
      final w = s.startWork();
      expect(w.phase, WorkoutPhase.work);
      expect(w.phaseSeconds, timedSetSeconds);
    });

    test('set -> rest -> next set; last set -> rating -> done', () {
      var s = start(
        session(items: const [BuiltItem(exerciseNumber: 1, sets: 2, reps: 8)]),
      ).startWork();
      s = s.finishStep();
      expect(s.phase, WorkoutPhase.rest);
      expect(s.index, 1);
      expect(s.phaseSeconds, 30);
      s = s.startWork().finishStep();
      expect(s.phase, WorkoutPhase.rating);
      s = s.rate(Effort.hard);
      expect(s.isDone, isTrue);
      expect(s.efforts, {1: Effort.hard});
      expect(s.completedExercises, [1]);
    });

    test(
      'per-side: left goes straight to right, no rest, rating after right',
      () {
        var s = start(
          session(
            items: const [
              BuiltItem(
                exerciseNumber: 5,
                sets: 1,
                holdSeconds: 20,
                perSide: true,
              ),
            ],
          ),
        ).startWork();
        expect(s.phaseSeconds, 20);
        s = s.finishStep();
        expect(s.phase, WorkoutPhase.work);
        expect(s.step.side, Side.right);
        s = s.finishStep();
        expect(s.phase, WorkoutPhase.rating);
      },
    );

    test('every new exercise is announced; drills skip the rating', () {
      var s = start(
        session(
          warmUp: [90, 91],
          items: const [BuiltItem(exerciseNumber: 1, sets: 1, reps: 5)],
          coolDown: [95],
        ),
      ).startWork();
      s = s.finishStep();
      expect(s.phase, WorkoutPhase.rest); // announces the second drill
      expect(s.isIntro, isTrue);
      expect(s.phaseSeconds, 30); // the configured rest
      s = s.startWork().finishStep();
      expect(s.phase, WorkoutPhase.rest);
      expect(s.isIntro, isTrue);
      expect(s.step.exerciseNumber, 1);
      s = s.startWork().finishStep().rate(null);
      expect(s.phase, WorkoutPhase.rest);
      expect(s.step.kind, StepKind.coolDown);
      expect(s.efforts, isEmpty); // skipped rating records nothing
      s = s.startWork().finishStep();
      expect(s.isDone, isTrue);
      expect(s.completedExercises, [1]);
    });

    test('actions in the wrong phase are ignored', () {
      final s = start(
        session(items: const [BuiltItem(exerciseNumber: 1, sets: 1, reps: 5)]),
      );
      expect(s.finishStep().phase, WorkoutPhase.preview);
      expect(s.rate(Effort.easy).phase, WorkoutPhase.preview);
    });

    test('empty session is immediately done', () {
      expect(WorkoutState.start(buildSteps(session())).isDone, isTrue);
    });
  });

  group('previous and skip exercise', () {
    final s3 = session(
      warmUp: [90],
      items: const [
        BuiltItem(exerciseNumber: 1, sets: 3, reps: 8),
        BuiltItem(exerciseNumber: 2, sets: 1, reps: 8),
      ],
    );
    test('previous goes back one step in work; no-op at the start', () {
      var st = WorkoutState.start(buildSteps(s3));
      expect(st.previous().index, 0);
      st = st.copyWith(index: 2, phase: WorkoutPhase.rest);
      final back = st.previous();
      expect(back.index, 1);
      expect(back.phase, WorkoutPhase.work);
    });

    test('skipExercise jumps past all sets and is not counted done', () {
      var st = WorkoutState.start(buildSteps(s3)).startWork().finishStep();
      expect(st.step.exerciseNumber, 1); // moved on to rest before exercise 1
      st = st.startWork().skipExercise();
      expect(st.step.exerciseNumber, 2);
      expect(st.phase, WorkoutPhase.rest);
      expect(st.completedExercises, isNot(contains(1)));
      st = st.startWork().finishStep().rate(null);
      expect(st.isDone, isTrue);
      expect(st.completedExercises, [2]);
    });
  });

  test('formatTimer pads minutes', () {
    expect(formatTimer(50), '00:50');
    expect(formatTimer(65), '01:05');
  });

  group('ProgressionFeedback', () {
    const ladder = [10, 11, 12, 13];
    test('earned when every top-rung item is Easy', () {
      expect(
        ProgressionFeedback.readyForNextStep(
          ladder: ladder,
          sessionExercises: [10, 11, 12],
          efforts: {10: Effort.hard, 11: Effort.justRight, 12: Effort.easy},
        ),
        'Ready for the next step',
      );
    });
    test('not earned for just right, hard, unrated or empty', () {
      for (final efforts in [
        {12: Effort.justRight},
        {12: Effort.hard},
        <int, Effort>{},
      ]) {
        expect(
          ProgressionFeedback.readyForNextStep(
            ladder: ladder,
            sessionExercises: [11, 12],
            efforts: efforts,
          ),
          isNull,
        );
      }
      expect(
        ProgressionFeedback.readyForNextStep(
          ladder: ladder,
          sessionExercises: [],
          efforts: {},
        ),
        isNull,
      );
    });
    test('not claimed at the top of the ladder or off-ladder', () {
      expect(
        ProgressionFeedback.readyForNextStep(
          ladder: ladder,
          sessionExercises: [13],
          efforts: {13: Effort.easy},
        ),
        isNull,
      );
      expect(
        ProgressionFeedback.readyForNextStep(
          ladder: ladder,
          sessionExercises: [99],
          efforts: {99: Effort.easy},
        ),
        isNull,
      );
    });
  });

  group('labels and voice cues', () {
    test('labels', () {
      const s = WorkoutStep(
        exerciseNumber: 1,
        kind: StepKind.set,
        setNumber: 2,
        totalSets: 3,
        side: Side.left,
        seconds: 20,
      );
      expect(s.targetLabel, '20 s hold');
      expect(s.progressLabel, 'Set 2 of 3 · Left side');
      expect(formatClock(65), '1:05');
    });

    test('cue schedule respects mode and halfway toggle', () {
      const step = WorkoutStep(
        exerciseNumber: 1,
        kind: StepKind.set,
        seconds: 30,
      );
      const off = VoiceCuePlanner(mode: VoiceCueMode.off);
      expect(off.onStepStart(step, 'Plank'), isNull);
      expect(off.halfwaySecond(step), isNull);
      const brief = VoiceCuePlanner(mode: VoiceCueMode.brief);
      expect(brief.onStepStart(step, 'Plank', cue: 'Brace')!.text, 'Plank');
      expect(brief.halfwaySecond(step), 15);
      const detailed = VoiceCuePlanner(
        mode: VoiceCueMode.detailed,
        halfway: false,
      );
      expect(
        detailed.onStepStart(step, 'Plank', cue: 'Brace')!.text,
        'Plank. Brace',
      );
      expect(detailed.halfwaySecond(step), isNull);
    });
  });
}
