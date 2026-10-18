import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/shared_preferences_provider.dart';
import '../../data/subscription_service.dart';
import '../../domain/paywall_offer.dart';
import '../../domain/subscription.dart';

/// RevenueCat when its key is set for this build, otherwise the local test
/// store (purchases work on the phone without payment).
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final key = RevenueCatSubscriptionService.platformKey();
  return key == null
      ? LocalSubscriptionService(prefs, allowPurchases: !kReleaseMode)
      : RevenueCatSubscriptionService(prefs, key);
});

/// The user's subscription. Starts from the saved status (instant, works
/// offline) and is refreshed from the store in the background.
final subscriptionProvider =
    NotifierProvider<SubscriptionNotifier, SubscriptionStatus>(
      SubscriptionNotifier.new,
    );

class SubscriptionNotifier extends Notifier<SubscriptionStatus> {
  SubscriptionService get _service => ref.read(subscriptionServiceProvider);

  @override
  SubscriptionStatus build() {
    final service = ref.watch(subscriptionServiceProvider);
    Future.microtask(() async {
      final fresh = await service.refresh();
      if (ref.mounted && fresh != state) state = fresh;
    });
    return service.cached;
  }

  Future<SubscriptionStatus> purchase(PremiumPlan plan) async {
    final s = await _service.purchase(plan);
    state = s;
    return s;
  }

  Future<SubscriptionStatus> restore() async {
    final s = await _service.restore();
    state = s;
    return s;
  }

  Future<void> cancel() async => state = await _service.cancel();

  /// After sign-in / sign-out: the subscription belongs to the account.
  Future<void> setAccount(String? uid) async {
    await _service.setAccount(uid);
    state = await _service.refresh();
  }
}

/// The offers shown on the paywall (store prices once RevenueCat is live).
final paywallOffersProvider = FutureProvider<List<PaywallOffer>>(
  (ref) => ref.watch(subscriptionServiceProvider).offers(),
);
