import 'dart:convert';

import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/features/onboarding/data/onboarding_flow.dart';
import 'package:calisthenics/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders every onboarding step with a realistic set of answers and fails on
/// any exception other than the harmless test-font overflow.
void main() {
  const answers = {
    'main-goal': ['master-calisthenics-skills'],
    'training-space': ['both'],
    'equipment': ['pull-up-bar', 'resistance-band'],
    'areas-to-protect': ['knees'],
    'training-experience': ['some-experience'],
    'days-per-week': ['days-4'],
    'workout-duration': ['20-min'],
    'time-of-day': ['morning'],
    'plan-choice': ['skill-pull-up'],
    'skill-ability': ['dead-hang'],
  };

  for (var i = 0; i < onboardingSteps.length; i++) {
    final id = onboardingSteps[i].id;
    testWidgets('renders step $i ($id)', (tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_schema_version': 3,
        'onboarding_index': i,
        'onboarding_name': 'Sam',
        'onboarding_plank_seconds': 34,
        'onboarding_selections': jsonEncode(answers),
      });
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final errors = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.exceptionAsString());
      addTearDown(() => FlutterError.onError = previous);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const CalestheticsApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));

      expect(
        errors.where((e) => !e.contains('overflowed')),
        isEmpty,
        reason: 'step $id threw',
      );
    });
  }
}
