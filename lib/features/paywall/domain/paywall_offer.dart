import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One subscription the user can buy. Every field comes from the store (via
/// RevenueCat) so prices are localised and never typed into the app.
class PaywallOffer {
  const PaywallOffer({
    required this.id,
    required this.title,
    required this.priceLabel,
    this.trialLabel,
  });

  final String id;

  /// Package name, e.g. "Yearly".
  final String title;

  /// Localised price with its period, exactly as the store formats it.
  final String priceLabel;

  /// Store-provided trial description, when the offer has a trial.
  final String? trialLabel;
}

enum PaywallOffersStatus { unavailable, available }

/// What the paywall can currently offer.
class PaywallOffers {
  const PaywallOffers.unavailable()
    : status = PaywallOffersStatus.unavailable,
      offers = const [];

  const PaywallOffers.available(this.offers)
    : status = PaywallOffersStatus.available;

  final PaywallOffersStatus status;
  final List<PaywallOffer> offers;

  bool get isAvailable =>
      status == PaywallOffersStatus.available && offers.isNotEmpty;
}

/// Offers for the paywall. RevenueCat is not integrated yet, so this is
/// always unavailable and the UI says so instead of showing any price. Swap
/// the body for the RevenueCat offerings fetch when it lands.
final paywallOffersProvider = Provider<PaywallOffers>(
  (ref) => const PaywallOffers.unavailable(),
);
