import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/features/onboarding/data/onboarding_flow.dart';
import 'package:calisthenics/features/onboarding/domain/onboarding_step.dart';
import 'package:calisthenics/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:calisthenics/shared/models/calisthenics_skill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('option ids are unique within every step', () {
    for (final step in onboardingSteps) {
      final ids = switch (step) {
        ChoiceStep() => step.options.map((o) => o.id).toList(),
        FocusStep() => step.areas.map((a) => a.id).toList(),
        _ => <String>[],
      };
      expect(
        ids.toSet().length,
        ids.length,
        reason: 'duplicate option id in ${step.id}',
      );
    }
    for (final skill in calisthenicsSkills) {
      final ids = skill.abilityLevels.map((o) => o.id).toList();
      expect(
        ids.toSet().length,
        ids.length,
        reason: 'duplicate ability id in ${skill.id}',
      );
    }
  });

  test('saved index selections are migrated to stable ids once', () async {
    final container = await _container({
      'onboarding_selections': '{"areas-to-protect":[1,3],"dream-skill":[1],"skill-ability":[2],"main-goal":[0]}',
    });
    final state = container.read(onboardingControllerProvider);
    expect(state.selections['areas-to-protect'], {'wrists', 'lower-back'});
    expect(state.selections['skill-ability'], {'band-assisted'});
    expect(state.selections['main-goal'], {'get-stronger'});
    expect(state.selections.containsKey('dream-skill'), isFalse);
  });

  test('already-migrated data is left untouched', () async {
    final container = await _container({
      'onboarding_schema_version': 2,
      'onboarding_selections': '{"areas-to-protect":["knees"]}',
    });
    expect(
      container
          .read(onboardingControllerProvider)
          .selections['areas-to-protect'],
      {'knees'},
    );
  });
}
