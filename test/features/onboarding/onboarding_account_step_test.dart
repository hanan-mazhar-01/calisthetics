import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/auth/presentation/providers/auth_providers.dart';
import 'package:calisthenics/features/onboarding/data/onboarding_flow.dart';
import 'package:calisthenics/features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeUser implements User {
  @override
  String get uid => 'test-user';
  @override
  String? get email => 'test@example.com';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Opens onboarding on the paywall (the step before the sign-in step).
Future<SharedPreferences> _atPaywall(
  WidgetTester tester, {
  required bool signedIn,
}) async {
  SharedPreferences.setMockInitialValues({
    'onboarding_schema_version': 3,
    'onboarding_index': onboardingSteps.indexWhere((s) => s.id == 'paywall'),
  });
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const OnboardingFlowScreen()),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('HOME')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUserProvider.overrideWithValue(signedIn ? _FakeUser() : null),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pump(const Duration(seconds: 2));
  return prefs;
}

void main() {
  testWidgets('guest: after the paywall comes the sign-in step', (
    tester,
  ) async {
    await _atPaywall(tester, signedIn: false);
    await tester.tap(find.text('Not now'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('signed in: the paywall finishes onboarding, no sign-in step', (
    tester,
  ) async {
    final prefs = await _atPaywall(tester, signedIn: true);
    await tester.tap(find.text('Not now'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Continue with Google'), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
    expect(prefs.getBool('onboarding_completed'), isTrue);
    expect(prefs.getString('user_plans'), isNotNull);
  });

  testWidgets('Android: the sign-in step offers Google and email, not Apple', (
    tester,
  ) async {
    await _atPaywall(tester, signedIn: false);
    await tester.tap(find.text('Not now'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with email'), findsOneWidget);
  });

  testWidgets('iPhone: the sign-in step also offers Apple', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await _atPaywall(tester, signedIn: false);
      await tester.tap(find.text('Not now'));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
