import 'package:calisthenics/features/exercises/data/exercise_catalog.dart';
import 'package:calisthenics/features/plans/data/plan_templates.dart';
import 'package:calisthenics/features/plans/domain/exercise_constraints.dart';
import 'package:calisthenics/features/plans/domain/plan_builder.dart';
import 'package:calisthenics/features/plans/domain/plan_recommender.dart';
import 'package:calisthenics/features/plans/domain/plan_template.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  planEditingTests();
  test('there are 13 templates with unique ids', () {
    expect(planTemplates.length, 13);
    expect(planTemplates.map((t) => t.id).toSet().length, 13);
  });

  test(
    'templates reference only real catalog exercises and cover all 98 videos',
    () {
      final byNumber = {for (final e in exerciseCatalog) e.number: e};
      final covered = <String>{};
      for (final t in planTemplates) {
        for (final n in t.exerciseNumbers) {
          expect(
            byNumber.containsKey(n),
            isTrue,
            reason: '${t.id} uses unknown exercise $n',
          );
          covered.add(byNumber[n]!.videoFile);
        }
      }
      final missing = exerciseCatalog
          .map((e) => e.videoFile)
          .toSet()
          .difference(covered);
      expect(missing, isEmpty);
    },
  );

  group('PlanRecommender', () {
    const recommender = PlanRecommender();

    test('exactly one "best for you" and it is usable today', () {
      final r = recommender.recommend(const UserProfile());
      expect(r.where((e) => e.bestForYou).length, 1);
      expect(r.firstWhere((e) => e.bestForYou).isAvailable, isTrue);
    });

    test('goal drives the top pick', () {
      expect(
        recommender
            .recommend(const UserProfile(goal: PrimaryGoal.toneBody))
            .first
            .template
            .id,
        'legs-and-glutes',
      );
      expect(
        recommender
            .recommend(const UserProfile(goal: PrimaryGoal.improveFitness))
            .first
            .template
            .id,
        'express-conditioning',
      );
    });

    test('a missing pull-up bar keeps bar plans from being best', () {
      final r = recommender.recommend(
        const UserProfile(
          goal: PrimaryGoal.masterSkills,
          level: PlanLevel.advanced,
        ),
      );
      final best = r.firstWhere((e) => e.bestForYou).template;
      expect(
        best.gear.contains(PlanGear.pullUpBar) ||
            best.gear.contains(PlanGear.parallelBars),
        isFalse,
      );
    });

    test('protected wrists rule out handstand as best', () {
      final r = recommender.recommend(
        const UserProfile(
          goal: PrimaryGoal.masterSkills,
          protectedAreas: {ProtectedArea.wrists},
          space: TrainingSpace.gym,
        ),
      );
      expect(
        r.firstWhere((e) => e.template.id == 'skill-handstand').conflicts,
        contains(ProtectedArea.wrists),
      );
      expect(r.firstWhere((e) => e.bestForYou).template.strainsWrists, isFalse);
    });
  });

  group('UserProfile.fromSelections', () {
    test('maps onboarding option ids', () {
      final p = UserProfile.fromSelections({
        'main-goal': {'master-calisthenics-skills'},
        'training-experience': {'beginner'},
        'fitness-profile': {'fairly-strong'},
        'training-space': {'gym'},
        'areas-to-protect': {'knees', 'neck'},
        'workout-duration': {'20-min'},
      });
      expect(p.goal, PrimaryGoal.masterSkills);
      expect(p.level, PlanLevel.intermediate);
      expect(p.space, TrainingSpace.gym);
      expect(p.protectedAreas, {ProtectedArea.knees, ProtectedArea.neck});
      expect(p.sessionMinutes, 20);
    });
  });

  group('PlanBuilder', () {
    const builder = PlanBuilder();
    final template = planTemplates.firstWhere((t) => t.id == 'skill-push-up');

    test('schedules the chosen number of training days', () {
      final w = builder.buildWeek(
        template,
        const UserProfile(daysPerWeek: 4),
        week: 1,
      );
      expect(w.days.where((d) => !d.isRest).length, 4);
      expect(w.days.length, 7);
    });

    test('sessions fit the time the user chose', () {
      for (final minutes in [10, 15, 20]) {
        final w = builder.buildWeek(
          template,
          UserProfile(sessionMinutes: minutes),
          week: 1,
        );
        for (final d in w.days.where((d) => !d.isRest)) {
          expect(d.session!.items.length, greaterThanOrEqualTo(3));
          // Three-item floor can exceed the budget slightly on very short sessions.
          if (d.session!.items.length > 3) {
            expect(d.session!.estimatedMinutes, lessThanOrEqualTo(minutes + 1));
          }
        }
      }
    });

    test('volume rises over weeks 1-3 and drops in deload week 4', () {
      int firstReps(int week) => builder
          .buildWeek(
            template,
            const UserProfile(sessionMinutes: 20),
            week: week,
          )
          .days
          .firstWhere((d) => !d.isRest)
          .session!
          .items
          .first
          .reps!;
      expect(firstReps(2), greaterThan(firstReps(1)));
      expect(firstReps(3), greaterThan(firstReps(2)));
      final w4 = builder.buildWeek(
        template,
        const UserProfile(sessionMinutes: 30),
        week: 4,
      );
      expect(w4.isDeload, isTrue);
      expect(firstReps(4), lessThan(firstReps(3)));
    });

    test('level picks the starting stage; stage advances at 75% adherence', () {
      expect(
        builder.startingStage(
          template,
          const UserProfile(level: PlanLevel.advanced),
        ),
        2,
      );
      expect(
        builder.nextStage(template, 0, sessionsDone: 9, sessionsPlanned: 12),
        1,
      );
      expect(
        builder.nextStage(template, 0, sessionsDone: 5, sessionsPlanned: 12),
        0,
      );
      expect(
        builder.nextStage(template, 2, sessionsDone: 12, sessionsPlanned: 12),
        2,
      );
    });
  });
}

void planEditingTests() {
  group('PlanBuilder with edited preferences', () {
    const builder = PlanBuilder();
    final pushUp = planTemplates.firstWhere((t) => t.id == 'skill-push-up');
    final full = planTemplates.firstWhere(
      (t) => t.id == 'foundation-full-body',
    );

    Iterable<int> numbers(BuiltWeek w) => [
      for (final d in w.days)
        if (d.session != null) ...d.session!.items.map((i) => i.exerciseNumber),
    ];

    test('protecting wrists removes wrist-loading exercises', () {
      final w = builder.buildWeek(
        pushUp,
        const UserProfile(
          protectedAreas: {ProtectedArea.wrists},
          level: PlanLevel.intermediate,
          sessionMinutes: 20,
        ),
        week: 1,
      );
      for (final n in numbers(w)) {
        expect(
          loadsProtectedArea(n, {ProtectedArea.wrists}),
          isFalse,
          reason: 'exercise $n loads wrists',
        );
      }
    });

    test('a focus area adds a matching accessory to each session', () {
      final base = builder.buildWeek(
        full,
        const UserProfile(sessionMinutes: 20),
        week: 1,
      );
      final core = builder.buildWeek(
        full,
        const UserProfile(sessionMinutes: 20, focusAreas: {'core'}),
        week: 1,
      );
      final coreNumbers = {10, 11, 12, 13, 14, 15, 16};
      final baseCore = numbers(base).where(coreNumbers.contains).length;
      final withCore = numbers(core).where(coreNumbers.contains).length;
      expect(withCore, greaterThanOrEqualTo(baseCore));
      expect(
        core.days
            .where((d) => d.session != null)
            .every(
              (d) => d.session!.items.any(
                (i) => coreNumbers.contains(i.exerciseNumber),
              ),
            ),
        isTrue,
      );
    });

    test('a longer duration fills the session with more work', () {
      int minutes(int m) => builder
          .buildWeek(full, UserProfile(sessionMinutes: m), week: 1)
          .days
          .firstWhere((d) => d.session != null)
          .session!
          .estimatedMinutes;
      expect(minutes(30), greaterThan(minutes(10)));
      expect(minutes(30), lessThanOrEqualTo(30));
    });

    test('no exercise appears twice in a session', () {
      final w = builder.buildWeek(
        full,
        const UserProfile(sessionMinutes: 30, focusAreas: {'core', 'legs'}),
        week: 1,
      );
      for (final d in w.days.where((d) => d.session != null)) {
        final n = d.session!.items.map((i) => i.exerciseNumber).toList();
        expect(n.toSet().length, n.length);
      }
    });
  });
}
