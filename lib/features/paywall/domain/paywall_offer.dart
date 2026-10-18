import 'subscription.dart';

/// One subscription on the paywall. With RevenueCat connected, the price
/// comes from the store (localised); until then the launch prices are used.
class PaywallOffer {
  const PaywallOffer({
    required this.plan,
    required this.price,
    required this.period,
    this.trialDays,
    this.perMonth,
  });

  final PremiumPlan plan;

  /// e.g. "$9.99".
  final String price;

  /// "month" or "year".
  final String period;

  /// Free trial length, when the offer has one.
  final int? trialDays;

  /// Yearly price broken down per month, e.g. "$4.17".
  final String? perMonth;

  String get title => plan == PremiumPlan.yearly ? 'Yearly' : 'Monthly';
}

/// Launch prices: $9.99/month with a 7-day free trial, $49.99/year.
const defaultPaywallOffers = [
  PaywallOffer(
    plan: PremiumPlan.monthly,
    price: r'$9.99',
    period: 'month',
    trialDays: 7,
  ),
  PaywallOffer(
    plan: PremiumPlan.yearly,
    price: r'$49.99',
    period: 'year',
    perMonth: r'$4.17',
  ),
];
