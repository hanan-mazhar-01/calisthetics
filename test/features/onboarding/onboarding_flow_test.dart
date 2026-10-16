import 'dart:convert';

import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/features/onboarding/data/onboarding_flow.dart';
import 'package:calisthenics/features/onboarding/domain/onboarding_plan_summary.dart';
import 'package:calisthenics/features/onboarding/domain/onboarding_step.dart';
import 'package:calisthenics/features/onboarding/domain/skill_abilities.dart';
import 'package:calisthenics/features/onboarding/presentation/onboarding_dynamic_content.dart';
import 'package:calisthenics/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:calisthenics/features/plans/data/plan_templates.dart';
import 'package:calisthenics/features/plans/domain/plan_template.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:calisthenics/features/user/presentation/providers/user_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

int _indexOf(String id) => onboardingSteps.indexWhere((s) => s.id == id);

void main() {
  group('flow order', () {
    test('step ids are unique', () {
      final ids = onboardingSteps.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('follows the final order from the brief', () {
      const expected = [
        'welcome',
        'age',
        'part-1-goal',
        'main-goal',
        'additional-goals',
        'potential',
        'training-space',
        'equipment',
        'part-2-you',
        'name',
        'areas-to-protect',
        'part-3-fitness',
        'training-experience',
        'endurance',
        'plank-test',
        'personalized-projection',
        'why-calesthetics-different',
        'part-4-plan',
        'focus-areas',
        'time-of-day',
        'days-per-week',
        'workout-duration',
        'intensity',
        'relate',
        'emotional-benefit',
        'health-note',
        'plan-selection',
        'skill-ability',
        'encouragement',
        'plan-creation',
        'personalized-result',
        'plan-content',
        'plan-preview',
        'train-anywhere',
        'exercise-library',
        'paywall',
        'account',
      ];
      expect([for (final s in onboardingSteps) s.id], expected);
    });

    test('the removed steps are gone', () {
      for (final id in ['daily-activity', 'fitness-profile', 'story-dynamic']) {
        expect(_indexOf(id), -1, reason: id);
      }
    });

    test('plank test comes before the projection that uses it', () {
      expect(
        _indexOf('plank-test'),
        lessThan(_indexOf('personalized-projection')),
      );
    });
  });

  group('exclusive None', () {
    test(
      'choosing None clears the others; any other choice clears None',
      () async {
        final c = await _container();
        final n = c.read(onboardingControllerProvider.notifier);
        n.toggleOption('areas-to-protect', 'wrists', multi: true);
        n.toggleOption('areas-to-protect', 'knees', multi: true);
        expect(n.selectionsFor('areas-to-protect'), {'wrists', 'knees'});
        n.toggleOption('areas-to-protect', 'none', multi: true);
        expect(n.selectionsFor('areas-to-protect'), {'none'});
        n.toggleOption('areas-to-protect', 'neck', multi: true);
        expect(n.selectionsFor('areas-to-protect'), {'neck'});
        n.toggleOption('areas-to-protect', 'none', multi: true);
        n.toggleOption('areas-to-protect', 'none', multi: true);
        expect(n.selectionsFor('areas-to-protect'), isEmpty);
      },
    );

    test('the equipment step is exclusive too', () async {
      final c = await _container();
      final n = c.read(onboardingControllerProvider.notifier);
      n.toggleOption('equipment', 'pull-up-bar', multi: true);
      n.toggleOption('equipment', 'none', multi: true);
      expect(n.selectionsFor('equipment'), {'none'});
    });

    test('non-exclusive multi steps are unaffected', () async {
      final c = await _container();
      final n = c.read(onboardingControllerProvider.notifier);
      n.toggleOption('additional-goals', 'stronger-core', multi: true);
      n.toggleOption('additional-goals', 'none', multi: true);
      expect(n.selectionsFor('additional-goals'), {'stronger-core', 'none'});
    });
  });

  group('UserProfile.fromSelections (new answers)', () {
    test('days per week, time of day and space', () {
      final p = UserProfile.fromSelections({
        'days-per-week': {'days-5'},
        'time-of-day': {'evening'},
        'training-space': {'both'},
      });
      expect(p.daysPerWeek, 5);
      expect(p.timeOfDay, TrainingTime.evening);
      expect(p.space, TrainingSpace.both);
      expect(UserProfile.fromSelections({}).daysPerWeek, 3);
    });

    test('equipment: None keeps just the wall; choices map to gear', () {
      expect(UserProfile.fromSelections({}).equipmentOverride, isNull);
      expect(
        UserProfile.fromSelections({
          'equipment': {'none'},
        }).equipmentOverride,
        {PlanGear.wall},
      );
      expect(
        UserProfile.fromSelections({
          'equipment': {'pull-up-bar', 'resistance-band', 'chair-box'},
        }).gear,
        {PlanGear.wall, PlanGear.pullUpBar, PlanGear.band, PlanGear.chair},
      );
    });

    test('plank seconds and focus areas carry through, and survive JSON', () {
      final p = UserProfile.fromSelections({
        'focus-areas': {'core'},
        'time-of-day': {'morning'},
        'equipment': {'parallettes'},
      }, plankSeconds: 42);
      final back = UserProfile.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
      );
      expect(back.plankSeconds, 42);
      expect(back.focusAreas, {'core'});
      expect(back.timeOfDay, TrainingTime.morning);
      expect(back.gear, {PlanGear.wall, PlanGear.parallelBars});
    });

    test('the ability answer sets the starting level for a skill plan', () {
      UserProfile p(String ability) => UserProfile.fromSelections({
        'training-experience': {'beginner'},
        'plan-choice': {'skill-pull-up'},
        'skill-ability': {ability},
      });
      expect(p('not-yet').level, PlanLevel.beginner);
      expect(p('negative-pull-up').level, PlanLevel.intermediate);
      expect(p('full-pull-up').level, PlanLevel.advanced);
      // An answer from another plan's list is ignored.
      expect(p('wall-push-up').level, PlanLevel.beginner);
    });

    test('a general ability answer can only raise the level', () {
      final p = UserProfile.fromSelections({
        'training-experience': {'advanced'},
        'plan-choice': {'foundation-full-body'},
        'skill-ability': {'general-new'},
      });
      expect(p.level, PlanLevel.advanced);
    });
  });

  group('ability options', () {
    test(
      'every skill plan has a skill list of five ids that map to exercises',
      () {
        for (final t in planTemplates.where((t) => t.skillId != null)) {
          final list = abilitiesFor(t.skillId);
          expect(list, hasLength(5), reason: t.id);
          expect(list.every((a) => a.exerciseNumber != null), isTrue);
        }
      },
    );

    test('dips use #69-#74, toes-to-bar uses #89, pistol is #48 then #49', () {
      expect([
        for (final a in abilitiesFor('dips')) a.exerciseNumber,
      ], everyElement(inInclusiveRange(69, 74)));
      expect(
        abilitiesFor('toes-to-bar').map((a) => a.exerciseNumber),
        contains(89),
      );
      final pistol = abilitiesFor('pistol-squat')
          .map((a) => a.exerciseNumber)
          .toList();
      expect(pistol.indexOf(48), lessThan(pistol.indexOf(49)));
    });
  });

  group('plan summary uses real PlanBuilder values', () {
    final today = DateTime(2026, 10, 12);

    test('sessions follow the chosen days; four phases; real weekdays', () {
      final s = OnboardingPlanSummary.from({
        'plan-choice': {'skill-push-up'},
        'days-per-week': {'days-4'},
        'workout-duration': {'20-min'},
      }, today: today)!;
      expect(s.sessionsPerWeek, 4);
      expect(s.phases, hasLength(4));
      expect(s.calendar, hasLength(7));
      expect(s.calendar.where((d) => d.isTraining), hasLength(4));
      expect(s.targetDate, DateTime(2026, 11, 9));
      expect(s.minutesLabel, endsWith('min'));
      expect(s.phases.every((p) => p.exercises.isNotEmpty), isTrue);
    });

    test('is null until a plan is chosen', () {
      expect(OnboardingPlanSummary.from({}, today: today), isNull);
    });

    test(
      'recommendations never put a plan with a protected conflict first',
      () {
        final recs = recommendationsFor({
          'main-goal': {'master-calisthenics-skills'},
          'equipment': {'parallettes'},
          'areas-to-protect': {'wrists', 'shoulders'},
        });
        final hero = heroRecommendation(recs);
        expect(hero.conflicts, isEmpty);
        expect(hero.missingGear, isEmpty);
      },
    );

    test('dynamic content: projection uses the measured plank seconds', () {
      final step = onboardingSteps.firstWhere(
        (s) => s.id == 'personalized-projection',
      );
      final patched = applyDynamicContent(step, plankSeconds: 25) as CurveStep;
      expect(patched.points.first.label, '25s');
      expect(patched.points.last.label, '30s');
      expect(patched.headline.accent, '30-second');
    });

    test('dynamic content: result and content steps show builder values', () {
      final selections = {
        'plan-choice': {'skill-pull-up'},
        'days-per-week': {'days-3'},
      };
      final plan = OnboardingPlanSummary.from(selections, today: today)!;
      final content = applyDynamicContent(
        onboardingSteps.firstWhere((s) => s.id == 'plan-content'),
        plan: plan,
      ) as PlanContentStep;
      expect(
        content.rows.firstWhere((r) => r.key == 'Sessions').value,
        '3 × week',
      );
      expect(content.calendar, hasLength(7));
      final preview = applyDynamicContent(
        onboardingSteps.firstWhere((s) => s.id == 'plan-preview'),
        plan: plan,
      ) as PlanPreviewStep;
      expect(preview.phases, hasLength(4));
    });
  });

  group('controller', () {
    test(
      'plank seconds are kept in state and stored as the first record',
      () async {
        final c = await _container();
        c.read(onboardingControllerProvider.notifier).setPlankSeconds(37);
        expect(c.read(onboardingControllerProvider).plankSeconds, 37);
        expect(c.read(recordsProvider)['plankSeconds'], 37);
      },
    );

    test('changing the plan drops the old ability answer', () async {
      final c = await _container();
      final n = c.read(onboardingControllerProvider.notifier);
      n.choosePlan('skill-pull-up');
      n.toggleOption('skill-ability', 'dead-hang', multi: false);
      n.choosePlan('skill-pull-up');
      expect(n.selectionsFor('skill-ability'), {'dead-hang'});
      n.choosePlan('skill-push-up');
      expect(n.selectionsFor('skill-ability'), isEmpty);
    });

    test(
      'finishing starts the chosen plan with the profile and completes',
      () async {
        final c = await _container();
        final n = c.read(onboardingControllerProvider.notifier);
        n.toggleOption('days-per-week', 'days-4', multi: false);
        n.choosePlan('core-control');
        await n.startPlanAndFinish();
        final plan = c.read(activePlanProvider)!;
        expect(plan.templateId, 'core-control');
        expect(plan.profile.daysPerWeek, 4);
      },
    );

    test(
      'finishing without a choice falls back to the recommended plan',
      () async {
        final c = await _container();
        await c
            .read(onboardingControllerProvider.notifier)
            .startPlanAndFinish();
        expect(c.read(activePlanProvider), isNotNull);
        expect(
          c.read(onboardingControllerProvider).selections['plan-choice'],
          isNotEmpty,
        );
      },
    );
  });

  group('schema 3 migration', () {
    test(
      'remaps ids, merges strength into experience, restarts the position',
      () async {
        final c = await _container({
          'onboarding_schema_version': 2,
          'onboarding_index': 17,
          'onboarding_selections': jsonEncode({
            'training-space': ['outdoor'],
            'fitness-profile': ['fairly-strong'],
            'daily-activity': ['a-mix'],
            'skill-ability': ['bench-dips'],
            'areas-to-protect': ['knees'],
          }),
        });
        final s = c.read(onboardingControllerProvider);
        expect(s.index, 0);
        expect(s.selections['training-space'], {'both'});
        expect(s.selections['training-experience'], {'intermediate'});
        expect(s.selections.containsKey('fitness-profile'), isFalse);
        expect(s.selections.containsKey('daily-activity'), isFalse);
        expect(s.selections['skill-ability'], {'dip-support-hold'});
        expect(s.selections['areas-to-protect'], {'knees'});
      },
    );

    test(
      'an existing experience answer wins over the merged strength one',
      () async {
        final c = await _container({
          'onboarding_schema_version': 2,
          'onboarding_selections': jsonEncode({
            'training-experience': ['beginner'],
            'fitness-profile': ['strong-skilled'],
          }),
        });
        expect(
          c
              .read(onboardingControllerProvider)
              .selections['training-experience'],
          {'beginner'},
        );
      },
    );

    test('schema 1 index data still migrates through every step', () async {
      final c = await _container({
        'onboarding_selections':
            '{"training-space":[2],"fitness-profile":[3],"main-goal":[1]}',
      });
      final s = c.read(onboardingControllerProvider);
      expect(s.selections['training-space'], {'both'});
      expect(s.selections['training-experience'], {'advanced'});
      expect(s.selections['main-goal'], {'fit-tone-my-body'});
    });

    test('schema 3 data is left alone', () async {
      final c = await _container({
        'onboarding_schema_version': 3,
        'onboarding_index': 5,
        'onboarding_selections': jsonEncode({
          'equipment': ['none'],
        }),
      });
      final s = c.read(onboardingControllerProvider);
      expect(s.index, 5);
      expect(s.selections['equipment'], {'none'});
    });
  });

  test('every step has copy free of banned claims', () {
    final banned = RegExp(
      r'pilates|slim|burn|fat loss|calorie|no ads|bodyweight only',
      caseSensitive: false,
    );
    String text(OnboardingStep s) => switch (s) {
      ChoiceStep() =>
        '${s.headline.lead}${s.headline.accent}${s.headline.tail}${s.subtitle}'
            '${s.options.map((o) => '${o.label}${o.description}${o.feedbackBody}').join()}',
      PartIntroStep() => '${s.subtitle}${s.headline.accent}',
      HealthNoteStep() => '${s.subtitle}${s.headline.accent}',
      CurveStep() => '${s.footer}${s.headline.accent}',
      _ => '',
    };
    for (final s in onboardingSteps) {
      expect(banned.hasMatch(text(s)), isFalse, reason: s.id);
    }
  });
}
