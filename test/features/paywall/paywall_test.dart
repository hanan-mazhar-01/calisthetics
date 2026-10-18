import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/paywall/data/subscription_service.dart';
import 'package:calisthenics/features/paywall/domain/subscription.dart';
import 'package:calisthenics/features/paywall/presentation/providers/subscription_providers.dart';
import 'package:calisthenics/features/paywall/presentation/screens/paywall_screen.dart';
import 'package:calisthenics/features/paywall/presentation/widgets/subscription_pill.dart';
import 'package:calisthenics/features/plan/presentation/providers/plan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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
  group('test store', () {
    late SharedPreferences prefs;
    var now = DateTime(2026, 10, 18, 10);
    LocalSubscriptionService store() =>
        LocalSubscriptionService(prefs, clock: () => now);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      now = DateTime(2026, 10, 18, 10);
    });

    test('monthly starts a 7-day trial, then renews monthly', () async {
      final s = await store().purchase(PremiumPlan.monthly);
      expect(s.isPremium, isTrue);
      expect(s.inTrial, isTrue);
      expect(s.trialDaysLeft(now), 7);
      now = now.add(const Duration(days: 8));
      final later = store().cached;
      expect(later.inTrial, isFalse);
      expect(later.plan, PremiumPlan.monthly);
      expect(later.renewsAt!.isAfter(now), isTrue);
    });

    test('the trial is given once', () async {
      await store().purchase(PremiumPlan.monthly);
      await store().cancel();
      final again = await store().purchase(PremiumPlan.monthly);
      expect(again.inTrial, isFalse);
    });

    test('yearly has no trial and renews in a year', () async {
      final s = await store().purchase(PremiumPlan.yearly);
      expect(s.inTrial, isFalse);
      expect(s.renewsAt, DateTime(2027, 10, 18));
    });

    test('cancel goes back to free', () async {
      await store().purchase(PremiumPlan.yearly);
      final s = await store().cancel();
      expect(s.isPremium, isFalse);
      expect(store().cached.isPremium, isFalse);
    });
  });

  test('status labels under the name', () {
    final now = DateTime(2026, 10, 18);
    expect(
      SubscriptionPill.label(const SubscriptionStatus.free(), now),
      'Free plan',
    );
    expect(
      SubscriptionPill.label(
        SubscriptionStatus(
          plan: PremiumPlan.monthly,
          inTrial: true,
          trialEndsAt: now.add(const Duration(days: 5)),
        ),
        now,
      ),
      'Free trial · 5 days left',
    );
    expect(
      SubscriptionPill.label(
        const SubscriptionStatus(plan: PremiumPlan.yearly),
        now,
      ),
      'Premium · Yearly',
    );
  });

  testWidgets('monthly with the trial first; yearly on the switch', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);
    expect(find.textContaining(r'$9.99'), findsWidgets);
    expect(find.text('Start my free trial'), findsOneWidget);
    expect(find.text(r'7 days free, then $9.99/month'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    expect(find.text('Restore'), findsOneWidget);
    await tester.tap(find.text('Yearly'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining(r'$49.99'), findsWidgets);
    expect(find.text(r'Only $4.17 a month'), findsOneWidget);
  });

  testWidgets('choosing yearly changes the button; buying unlocks Premium', (
    tester,
  ) async {
    final container = await _pump(tester);
    await tester.tap(find.text('Yearly'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(r'Continue · $49.99/year'), findsOneWidget);
    expect(container.read(isPremiumProvider), isFalse);
    await tester.tap(find.text(r'Continue · $49.99/year'));
    await tester.pump(const Duration(seconds: 2));
    expect(container.read(isPremiumProvider), isTrue);
    expect(container.read(subscriptionProvider).plan, PremiumPlan.yearly);
    expect(find.text("Let's train"), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
