import 'package:calisthenics/features/paywall/data/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the iOS RevenueCat key is a public SDK key, never a secret one', () {
    const key = RevenueCatSubscriptionService.iosKey;
    expect(key, startsWith('appl_'));
    expect(key, isNot(startsWith('sk_')));
    expect(key.length, greaterThan(20));
  });

  test('the entitlement is the one set up in RevenueCat', () {
    expect(RevenueCatSubscriptionService.entitlementId, 'premium');
  });
}
