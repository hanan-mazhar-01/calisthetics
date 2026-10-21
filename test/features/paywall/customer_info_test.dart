import 'package:calisthenics/features/paywall/data/subscription_service.dart';
import 'package:calisthenics/features/paywall/domain/subscription.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

const _monthly = 'calisthenics_subscription_monthly';
const _yearly = 'calisthenics_subscription_yearly';
final _in7Days = DateTime.now().add(const Duration(days: 7)).toIso8601String();

Map<String, dynamic> _entitlement(
  String id,
  String product, {
  String period = 'NORMAL',
}) => {
  'identifier': id,
  'isActive': true,
  'willRenew': true,
  'latestPurchaseDate': '2026-10-20T10:00:00Z',
  'originalPurchaseDate': '2026-10-20T10:00:00Z',
  'productIdentifier': product,
  'isSandbox': true,
  'ownershipType': 'PURCHASED',
  'store': 'APP_STORE',
  'periodType': period,
  'expirationDate': _in7Days,
};

Map<String, dynamic> _sub(String product, {String period = 'NORMAL'}) => {
  'productIdentifier': product,
  'purchaseDate': '2026-10-20T10:00:00Z',
  'isSandbox': true,
  'isActive': true,
  'willRenew': true,
  'store': 'APP_STORE',
  'periodType': period,
  'expiresDate': _in7Days,
  'ownershipType': 'PURCHASED',
};

/// Customer info as RevenueCat reports it.
CustomerInfo _info({
  Map<String, Map<String, dynamic>> entitlements = const {},
  Map<String, Map<String, dynamic>> subs = const {},
  List<String> active = const [],
}) => CustomerInfo.fromJson({
  'entitlements': {
    'all': entitlements,
    'active': entitlements,
    'verification': 'NOT_REQUESTED',
  },
  'allPurchaseDates': <String, dynamic>{},
  'activeSubscriptions': active,
  'allPurchasedProductIdentifiers': active,
  'nonSubscriptionTransactions': <dynamic>[],
  'firstSeen': '2026-10-20T10:00:00Z',
  'originalAppUserId': 'user',
  'allExpirationDates': {for (final a in active) a: _in7Days},
  'requestDate': '2026-10-20T10:00:00Z',
  'latestExpirationDate': _in7Days,
  'subscriptionsByProductIdentifier': subs,
});

void main() {
  test('the premium entitlement: monthly in its free trial', () {
    final s = statusFromCustomerInfo(
      _info(
        entitlements: {
          'premium': _entitlement('premium', _monthly, period: 'TRIAL'),
        },
        active: [_monthly],
      ),
    );
    expect(s.plan, PremiumPlan.monthly);
    expect(s.inTrial, isTrue);
    expect(s.renewsAt, isNotNull);
  });

  test('the premium entitlement: yearly', () {
    final s = statusFromCustomerInfo(
      _info(
        entitlements: {'premium': _entitlement('premium', _yearly)},
        active: [_yearly],
      ),
    );
    expect(s.plan, PremiumPlan.yearly);
    expect(s.inTrial, isFalse);
  });

  test('an entitlement named otherwise still unlocks Premium', () {
    final s = statusFromCustomerInfo(
      _info(
        entitlements: {'pro': _entitlement('pro', _monthly)},
        active: [_monthly],
      ),
    );
    expect(s.isPremium, isTrue);
    expect(s.plan, PremiumPlan.monthly);
  });

  test(
    'a paid subscription with no entitlement at all is not left on Free',
    () {
      final monthly = statusFromCustomerInfo(
        _info(
          subs: {_monthly: _sub(_monthly, period: 'TRIAL')},
          active: [_monthly],
        ),
      );
      expect(monthly.plan, PremiumPlan.monthly);
      expect(monthly.inTrial, isTrue);

      final yearly = statusFromCustomerInfo(
        _info(subs: {_yearly: _sub(_yearly)}, active: [_yearly]),
      );
      expect(yearly.plan, PremiumPlan.yearly);
      expect(yearly.renewsAt, isNotNull);

      // Even with only the plain list of active subscriptions.
      expect(
        statusFromCustomerInfo(_info(active: [_yearly])).plan,
        PremiumPlan.yearly,
      );
    },
  );

  test('nothing active, or someone else\'s product: Free', () {
    expect(statusFromCustomerInfo(_info()).isPremium, isFalse);
    expect(
      statusFromCustomerInfo(
        _info(
          subs: {'other_app_sub': _sub('other_app_sub')},
          active: ['other_app_sub'],
        ),
      ).isPremium,
      isFalse,
    );
  });
}
