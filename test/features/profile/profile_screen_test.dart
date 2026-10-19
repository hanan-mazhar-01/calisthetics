import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/auth/presentation/providers/auth_providers.dart';
import 'package:calisthenics/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:calisthenics/features/profile/presentation/screens/profile_screen.dart';
import 'package:calisthenics/features/user/presentation/providers/user_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A signed-in account whose own name (say, from Google) is [displayName].
class _FakeUser implements User {
  _FakeUser(this.displayName);
  @override
  final String? displayName;
  @override
  String get uid => 'test-user';
  @override
  String? get email => 'test@example.com';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool dark = false,
  User? user,
  String name = 'Hanan',
}) async {
  tester.view.physicalSize = const Size(900, 3600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'onboarding_name': name});
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      if (user != null) currentUserProvider.overrideWithValue(user),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => const ProfileScreen())],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: dark ? AppTheme.dark : AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 2));
  return container;
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('renders groups and rows (dark: $dark)', (tester) async {
      await _pump(tester, dark: dark);
      for (final t in [
        'My Profile',
        'Hanan',
        'Guest · saved on this device',
        'Free plan',
        'Upgrade',
        'Reminders',
        'Light',
        'Dark',
        'Auto',
        'Help & Support',
        'Privacy Policy',
        'Terms of Use',
        'Sign in / Sign up',
        'Connect account',
        'Erase data on this phone',
        'Calesthetics 1.0.0',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      // Removed from Profile: these live elsewhere or are gone.
      for (final t in [
        'Personal info',
        'Change plan',
        'Equipment and areas to protect',
        'Retake assessment',
        'Favorites',
        'Restore purchases',
        'Sound',
        'Edit Profile',
      ]) {
        expect(find.text(t), findsNothing, reason: t);
      }
    });
  }

  testWidgets('editing the name saves it', (tester) async {
    final container = await _pump(tester);
    await tester.tap(find.byTooltip('Edit name'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'Sara');
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(container.read(onboardingControllerProvider).name, 'Sara');
    expect(find.text('Sara'), findsOneWidget);
  });

  testWidgets('signed in: an edited name replaces the account name', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      user: _FakeUser('Google Name'),
      name: 'Hanan',
    );
    // The name chosen in the app wins over the Google account's name.
    expect(find.text('Hanan'), findsOneWidget);
    expect(find.text('Google Name'), findsNothing);

    await tester.tap(find.byTooltip('Edit name'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'Sara');
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(container.read(onboardingControllerProvider).name, 'Sara');
    expect(find.text('Sara'), findsOneWidget);
    expect(find.text('Google Name'), findsNothing);
  });

  testWidgets('signed in with no name set: the account name is shown', (
    tester,
  ) async {
    await _pump(tester, user: _FakeUser('Google Name'), name: '');
    expect(find.text('Google Name'), findsOneWidget);
  });

  testWidgets(
    'guest: the row erases data on this phone, not "Delete Account"',
    (tester) async {
      await _pump(tester);
      expect(find.text('Delete Account'), findsNothing);
      await tester.tap(find.text('Erase data on this phone'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Erase data on this phone?'), findsOneWidget);
      expect(find.textContaining('Restore purchases'), findsOneWidget);
      expect(find.text('Erase'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Erase data on this phone?'), findsNothing);
    },
  );

  testWidgets('signed in: Delete Account asks for confirmation', (
    tester,
  ) async {
    await _pump(tester, user: _FakeUser('Google Name'));
    expect(find.text('Erase data on this phone'), findsNothing);
    await tester.tap(find.text('Delete Account'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Delete account?'), findsOneWidget);
    expect(find.textContaining('deleted from our servers'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Delete account?'), findsNothing);
  });

  testWidgets('appearance tabs switch the theme setting', (tester) async {
    final container = await _pump(tester);
    await tester.tap(find.text('Dark'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(settingsProvider)['themeMode'], 'dark');
    await tester.tap(find.text('Auto'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(settingsProvider)['themeMode'], 'system');
  });
}
