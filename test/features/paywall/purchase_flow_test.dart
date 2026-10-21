import 'dart:async';

import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/paywall/data/subscription_service.dart';
import 'package:calisthenics/features/paywall/domain/paywall_offer.dart';
import 'package:calisthenics/features/paywall/domain/subscription.dart';
import 'package:calisthenics/features/paywall/presentation/providers/subscription_providers.dart';
import 'package:calisthenics/features/paywall/presentation/screens/paywall_screen.dart';
import 'package:calisthenics/features/plan/presentation/providers/plan_providers.dart';
import 'package:calisthenics/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// RevenueCat stand-in whose purchases and outside changes the test drives.
class _Store implements SubscriptionService {
  SubscriptionStatus status = const SubscriptionStatus.free();
  final outside = StreamController<SubscriptionStatus>.broadcast();
  final bought = <PremiumPlan>[];

  @override
  bool get isLive => true;
  @override
  bool get canCancelInApp => false;
  @override
  SubscriptionStatus get cached => status;
  @override
  Stream<SubscriptionStatus> get changes => outside.stream;
  @override
  Future<SubscriptionStatus> refresh() async => status;
  @override
  Future<List<PaywallOffer>> offers() async => const [
    PaywallOffer(
      plan: PremiumPlan.monthly,
      price: r'$9.99',
      period: 'month',
      trialDays: 7,
      amount: 9.99,
    ),
    PaywallOffer(
      plan: PremiumPlan.yearly,
      price: r'$49.99',
      period: 'year',
      perMonth: r'$4.17',
      amount: 49.99,
    ),
  ];
  @override
  Future<SubscriptionStatus> purchase(PremiumPlan plan) async {
    bought.add(plan);
    final now = DateTime.now();
    return status = plan == PremiumPlan.monthly
        ? SubscriptionStatus(
            plan: plan,
            inTrial: true,
            trialEndsAt: now.add(const Duration(days: 7)),
            renewsAt: now.add(const Duration(days: 7)),
          )
        : SubscriptionStatus(
            plan: plan,
            renewsAt: now.add(const Duration(days: 365)),
          );
  }

  @override
  Future<SubscriptionStatus> restore() async => status;
  @override
  Future<SubscriptionStatus> cancel() async => status;
  @override
  Future<void> setAccount(String? uid) async {}
}

Future<(ProviderContainer, _Store)> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(900, 3600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final store = _Store();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      subscriptionServiceProvider.overrideWithValue(store),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.light, home: const PaywallScreen()),
    ),
  );
  await tester.pump(const Duration(seconds: 2));
  return (container, store);
}

void main() {
  testWidgets('buying monthly: the status, Profile and the button all update', (
    tester,
  ) async {
    final (container, store) = await _pump(tester);
    expect(container.read(isPremiumProvider), isFalse);

    await tester.tap(find.text('Start my free trial'));
    await tester.pump(const Duration(seconds: 2));
    expect(store.bought, [PremiumPlan.monthly]);
    final s = container.read(subscriptionProvider);
    expect(s.plan, PremiumPlan.monthly);
    expect(s.inTrial, isTrue);
    expect(container.read(isPremiumProvider), isTrue);
    // The welcome screen follows a purchase.
    expect(find.text("Let's train"), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));

    // The Profile screen, in the same app, shows the new plan.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('Free trial'), findsWidgets);
    expect(find.text('Free plan'), findsNothing);
  });

  testWidgets('after buying monthly the paywall says "Your current plan"; '
      'yearly stays buyable and then flips too', (tester) async {
    final (container, store) = await _pump(tester);
    store.status = SubscriptionStatus(
      plan: PremiumPlan.monthly,
      renewsAt: DateTime.now().add(const Duration(days: 30)),
    );
    container.invalidate(subscriptionProvider);
    await tester.pump(const Duration(seconds: 1));

    // Monthly is chosen by default: that is the plan the user has.
    expect(find.text('Your current plan'), findsOneWidget);
    // Yearly is something else: it can be bought.
    await tester.tap(find.text('Yearly'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(r'Continue · $49.99/year'), findsOneWidget);
    await tester.tap(find.text(r'Continue · $49.99/year'));
    await tester.pump(const Duration(seconds: 2));
    expect(container.read(subscriptionProvider).plan, PremiumPlan.yearly);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('a renewal, cancellation or expiry while the app is open '
      'updates everything at once', (tester) async {
    final (container, store) = await _pump(tester);
    container.read(subscriptionProvider); // start listening
    await tester.pump(const Duration(milliseconds: 100));

    // Bought on another device.
    store.outside.add(const SubscriptionStatus(plan: PremiumPlan.yearly));
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(subscriptionProvider).plan, PremiumPlan.yearly);
    expect(container.read(isPremiumProvider), isTrue);

    // It ends (cancelled and run out): Premium locks again.
    store.outside.add(const SubscriptionStatus.free());
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(subscriptionProvider).isPremium, isFalse);
    expect(container.read(isPremiumProvider), isFalse);
  });
}
