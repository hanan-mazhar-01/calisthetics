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
    this.amount,
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

  /// The price as a number (in the store's currency), to compare plans.
  final double? amount;

  String get title => plan == PremiumPlan.yearly ? 'Yearly' : 'Monthly';
}

/// Launch prices: $9.99/month with a 7-day free trial, $49.99/year.
const defaultPaywallOffers = [
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

/// How much cheaper the yearly plan is than twelve months of the monthly
/// one, in whole percent, worked out from the real prices; null when either
/// price is unknown or yearly is not cheaper. Never a number typed in by hand.
int? yearlySavingPercent(List<PaywallOffer> offers) {
  double? amount(PremiumPlan p) =>
      offers.where((o) => o.plan == p).firstOrNull?.amount;
  final monthly = amount(PremiumPlan.monthly);
  final yearly = amount(PremiumPlan.yearly);
  if (monthly == null || yearly == null || monthly <= 0) return null;
  final saving = ((1 - yearly / (monthly * 12)) * 100).round();
  return saving > 0 ? saving : null;
}
