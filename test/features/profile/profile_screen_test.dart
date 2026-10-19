import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/auth/presentation/providers/auth_providers.dart';
import 'package:calisthenics/features/paywall/data/subscription_service.dart';
import 'package:calisthenics/features/paywall/domain/paywall_offer.dart';
import 'package:calisthenics/features/paywall/domain/subscription.dart';
import 'package:calisthenics/features/paywall/presentation/providers/subscription_providers.dart';
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

/// RevenueCat stand-in: real payments, an active yearly plan, and a restore
/// that fails (no network).
class _LivePremium implements SubscriptionService {
  var restores = 0;
  @override
  bool get isLive => true;
  @override
  bool get canCancelInApp => false;
  @override
  SubscriptionStatus get cached =>
      const SubscriptionStatus(plan: PremiumPlan.yearly);
  @override
  Future<SubscriptionStatus> refresh() async => cached;
  @override
  Future<List<PaywallOffer>> offers() async => defaultPaywallOffers;
  @override
  Future<SubscriptionStatus> purchase(PremiumPlan plan) async => cached;
  @override
  Future<SubscriptionStatus> restore() async {
    restores++;
    throw Exception('offline');
  }

  @override
  Future<SubscriptionStatus> cancel() async => cached;
  @override
  Future<void> setAccount(String? uid) async {}
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool dark = false,
  User? user,
  String name = 'Hanan',
  SubscriptionService? store,
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
      if (store != null) subscriptionServiceProvider.overrideWithValue(store),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: '/support',
        builder: (_, _) => const Scaffold(body: Text('SUPPORT PAGE')),
      ),
    ],
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

  testWidgets('Manage: a store button, and a failed restore says so', (
    tester,
  ) async {
    final store = _LivePremium();
    await _pump(tester, store: store);
    await tester.tap(find.text('Manage'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Manage in Google Play'), findsOneWidget);
    expect(find.text('Switch to Monthly'), findsOneWidget);
    await tester.tap(find.text('Restore purchases'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(store.restores, 1);
    // No crash, and the user is told.
    expect(tester.takeException(), isNull);
    expect(
      find.text('Could not restore purchases. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('Help & Support opens the support page', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Help & Support'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('SUPPORT PAGE'), findsOneWidget);
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
