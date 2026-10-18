import 'dart:convert';
import 'dart:io';

import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/features/onboarding/data/onboarding_flow.dart';
import 'package:calisthenics/features/workout/domain/workout_request.dart';
import 'package:calisthenics/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Logical sizes (points) of the phones the app must fit.
const _devices = <(String, Size, double)>[
  ('iPhone SE 375x667', Size(375, 667), 2),
  ('iPhone 12 mini 375x812', Size(375, 812), 3),
  ('iPhone 11 / XR 414x896', Size(414, 896), 2),
  ('iPhone 12-14 390x844', Size(390, 844), 3),
  ('iPhone Pro Max 430x932', Size(430, 932), 3),
  ('Small Android 360x640', Size(360, 640), 2),
];

const _answers = {
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

/// Every onboarding step, on every device size and with larger system text:
/// no layout overflow and no exception.
/// Tests draw text in a blocky stand-in font that is far wider than the
/// app's real one, so overflow results would be false alarms. Load the real
/// fonts (Poppins and Lora, from assets) so the measured widths are true.
Future<void> _loadAppFonts() async {
  for (final (family, files) in [
    (
      'Poppins',
      ['Poppins-Regular', 'Poppins-Medium', 'Poppins-SemiBold', 'Poppins-Bold'],
    ),
    ('Lora', ['Lora-Medium']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('assets/google_fonts/$f.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(_loadAppFonts);
  for (final (name, size, dpr) in _devices) {
    for (final textScale in const [1.0, 1.3]) {
      // Larger text only on the smallest screens, where it matters most.
      if (textScale > 1 && size.height > 700) continue;
      for (var i = 0; i < onboardingSteps.length; i++) {
        final id = onboardingSteps[i].id;
        testWidgets('$name x$textScale · step $i ($id)', (tester) async {
          SharedPreferences.setMockInitialValues({
            'onboarding_schema_version': 3,
            'onboarding_index': i,
            'onboarding_name': 'Samantha',
            'onboarding_plank_seconds': 34,
            'onboarding_selections': jsonEncode(_answers),
          });
          final prefs = await SharedPreferences.getInstance();
          tester.view.physicalSize = size * dpr;
          tester.view.devicePixelRatio = dpr;
          tester.platformDispatcher.textScaleFactorTestValue = textScale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          final errors = <String>[];
          final previous = FlutterError.onError;
          FlutterError.onError = (d) =>
              errors.add(d.toString().split('\n').take(18).join('\n'));
          try {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
                child: const CalestheticsApp(),
              ),
            );
            await tester.pump(const Duration(milliseconds: 100));
            await tester.pump(const Duration(seconds: 2));
          } finally {
            FlutterError.onError = previous;
          }

          expect(errors, isEmpty, reason: errors.join('\n---\n'));
        });
      }
    }
  }

  // The finished app: every tab and the screens pushed from them.
  for (final (name, size, dpr) in _devices) {
    for (final textScale in const [1.0, 1.3]) {
      if (textScale > 1 && size.height > 700) continue;
      testWidgets('$name x$textScale · main app', (tester) async {
        SharedPreferences.setMockInitialValues({
          'onboarding_schema_version': 3,
          'onboarding_index': onboardingSteps.indexWhere(
            (s) => s.id == 'account',
          ),
          'onboarding_name': 'Samantha',
          'onboarding_plank_seconds': 34,
          'onboarding_selections': jsonEncode(_answers),
        });
        final prefs = await SharedPreferences.getInstance();
        tester.view.physicalSize = size * dpr;
        tester.view.devicePixelRatio = dpr;
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final errors = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (d) =>
            errors.add(d.toString().split('\n').take(14).join('\n'));
        Future<void> settle([int ms = 1200]) async {
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(Duration(milliseconds: ms));
        }

        void push(String location, {Object? extra}) {
          final ctx = tester.element(find.byType(Scaffold).first);
          GoRouter.of(ctx).push(location, extra: extra);
        }

        try {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
              child: const CalestheticsApp(),
            ),
          );
          await settle(2000);
          // Finish onboarding without an account: lands on the Plan tab.
          await tester.tap(find.textContaining('Skip and start my plan'));
          await settle(2500);
          expect(find.text('Personal Plan'), findsOneWidget);
          for (final (tab, heading) in [
            ('Discover', 'Discover'),
            ('Progress', 'Progress'),
            ('Profile', 'My Profile'),
            ('Plan', 'Personal Plan'),
          ]) {
            await tester.tap(find.bySemanticsLabel(tab).first);
            await settle();
            expect(find.text(heading), findsWidgets, reason: 'tab $tab');
          }
          for (final route in [
            '/paywall',
            '/privacy',
            '/terms',
            '/exercise/1',
            '/day/0',
            '/day/2',
          ]) {
            push(route);
            await settle(1500);
            GoRouter.of(tester.element(find.byType(Scaffold).first)).pop();
            await settle();
          }
          // The workout player (an exercise demo): its first 15 seconds.
          push('/workout', extra: WorkoutRequest.demo(1, 'Wall Push-Up'));
          await settle(1500);
          await tester.pump(const Duration(seconds: 12));
          await tester.pump(const Duration(seconds: 3));
        } finally {
          FlutterError.onError = previous;
        }
        expect(errors, isEmpty, reason: errors.join('\n---\n'));
      });
    }
  }
}
