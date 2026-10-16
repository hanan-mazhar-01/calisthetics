import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/features/onboarding/data/onboarding_flow.dart';
import 'package:calisthenics/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

int _indexOf(String id) => onboardingSteps.indexWhere((s) => s.id == id);

Future<ProviderContainer> _atPlanSelection(String planId) async {
  SharedPreferences.setMockInitialValues({
    'onboarding_schema_version': 3,
    'onboarding_index': _indexOf('plan-selection'),
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  container.read(onboardingControllerProvider.notifier).choosePlan(planId);
  return container;
}

void main() {
  test('a skill plan asks where you are today', () async {
    final c = await _atPlanSelection('skill-push-up');
    final controller = c.read(onboardingControllerProvider.notifier)..next();
    expect(
      c.read(onboardingControllerProvider).index,
      _indexOf('skill-ability'),
    );
    controller.back();
    expect(
      c.read(onboardingControllerProvider).index,
      _indexOf('plan-selection'),
    );
  });

  test(
    'a non-skill plan skips that question, going forward and back',
    () async {
      final c = await _atPlanSelection('express-conditioning');
      final controller = c.read(onboardingControllerProvider.notifier)..next();
      expect(
        c.read(onboardingControllerProvider).index,
        _indexOf('encouragement'),
      );
      controller.back();
      expect(
        c.read(onboardingControllerProvider).index,
        _indexOf('plan-selection'),
      );
    },
  );
}
