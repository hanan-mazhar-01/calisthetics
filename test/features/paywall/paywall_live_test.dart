import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/paywall/data/subscription_service.dart';
import 'package:calisthenics/features/paywall/domain/paywall_offer.dart';
import 'package:calisthenics/features/paywall/domain/subscription.dart';
import 'package:calisthenics/features/paywall/presentation/providers/subscription_providers.dart';
import 'package:calisthenics/features/paywall/presentation/screens/paywall_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A stand-in for RevenueCat: "live" payments whose offers the test controls.
class _LiveStore implements SubscriptionService {
  _LiveStore(this.available);

  List<PaywallOffer> available;
  int offerCalls = 0;
  final bought = <PremiumPlan>[];

  @override
  bool get isLive => true;
  @override
  Stream<SubscriptionStatus> get changes => const Stream.empty();
  @override
  bool get canCancelInApp => false;
  @override
  SubscriptionStatus get cached => const SubscriptionStatus.free();
  @override
  Future<SubscriptionStatus> refresh() async => cached;
  @override
  Future<List<PaywallOffer>> offers() async {
    offerCalls++;
    return available;
  }

  @override
  Future<SubscriptionStatus> purchase(PremiumPlan plan) async {
    bought.add(plan);
    return SubscriptionStatus(plan: plan);
  }

  @override
  Future<SubscriptionStatus> restore() async => cached;
  @override
  Future<SubscriptionStatus> cancel() async => cached;
  @override
  Future<void> setAccount(String? uid) async {}
}

const _monthly = PaywallOffer(
  plan: PremiumPlan.monthly,
  price: r'$12.99',
  period: 'month',
  trialDays: 7,
  amount: 12.99,
);
const _yearly = PaywallOffer(
  plan: PremiumPlan.yearly,
  price: r'$39.99',
  period: 'year',
  perMonth: r'$3.33',
  amount: 39.99,
);

Future<ProviderContainer> _pump(WidgetTester tester, _LiveStore store) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
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
  return container;
}

void main() {
  group('yearlySavingPercent', () {
    test('is worked out from the real prices', () {
      expect(yearlySavingPercent(defaultPaywallOffers), 58);
      expect(yearlySavingPercent(const [_monthly, _yearly]), 74);
    });

    test('is null when a price is unknown or yearly is not cheaper', () {
      expect(yearlySavingPercent(const []), isNull);
      expect(yearlySavingPercent(const [_monthly]), isNull);
      const dear = PaywallOffer(
        plan: PremiumPlan.yearly,
        price: r'$200',
        period: 'year',
        amount: 200,
      );
      expect(yearlySavingPercent(const [_monthly, dear]), isNull);
    });
  });

  testWidgets('real offers: the store price and trial, from the store', (
    tester,
  ) async {
    final store = _LiveStore(const [_monthly, _yearly]);
    await _pump(tester, store);
    expect(find.textContaining(r'$12.99'), findsWidgets);
    expect(find.text('Start my free trial'), findsOneWidget);
    expect(find.text(r'7 days free, then $12.99/month'), findsOneWidget);
    // Nothing typed in by hand shows next to the real prices.
    expect(find.textContaining(r'$9.99'), findsNothing);
    expect(find.text('Save 74%'), findsOneWidget);

    await tester.tap(find.text('Yearly'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(r'Continue · $39.99/year'), findsOneWidget);
    await tester.tap(find.text(r'Continue · $39.99/year'));
    await tester.pump(const Duration(seconds: 2));
    // The yearly plan was bought, not the monthly one.
    expect(store.bought, [PremiumPlan.yearly]);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('no trial offered (already used): no trial is promised', (
    tester,
  ) async {
    final store = _LiveStore([
      const PaywallOffer(
        plan: PremiumPlan.monthly,
        price: r'$12.99',
        period: 'month',
        amount: 12.99,
      ),
      _yearly,
    ]);
    await _pump(tester, store);
    expect(find.text('Start my free trial'), findsNothing);
    expect(find.text(r'Continue · $12.99/month'), findsOneWidget);
    expect(find.textContaining('days free'), findsNothing);
  });

  testWidgets('offers that cannot load: no made-up price, and Try again', (
    tester,
  ) async {
    final store = _LiveStore(const []);
    await _pump(tester, store);
    expect(find.textContaining(r'$9.99'), findsNothing);
    expect(find.textContaining(r'$49.99'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining('could not be loaded'), findsOneWidget);
    expect(find.text('Start my free trial'), findsNothing);
    expect(store.bought, isEmpty);
    expect(store.offerCalls, 1);

    // The store answers on the next try.
    store.available = const [_monthly, _yearly];
    await tester.tap(find.text('Try again'));
    await tester.pump(const Duration(seconds: 2));
    expect(store.offerCalls, 2);
    expect(find.text('Start my free trial'), findsOneWidget);
    expect(find.textContaining(r'$12.99'), findsWidgets);
  });

  testWidgets('the auto-renew terms sit by the button (Google Play)', (
    tester,
  ) async {
    await _pump(tester, _LiveStore(const [_monthly, _yearly]));
    expect(find.textContaining('at least 24 hours before'), findsOneWidget);
    expect(find.textContaining('Google Play'), findsOneWidget);
    expect(find.textContaining('when the free trial ends'), findsOneWidget);
  });

  testWidgets('the auto-renew terms name the Apple ID on iPhone', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await _pump(tester, _LiveStore(const [_monthly, _yearly]));
      expect(find.textContaining('Apple ID'), findsWidgets);
      expect(find.textContaining('Subscriptions'), findsOneWidget);
      expect(find.textContaining('Google Play'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
