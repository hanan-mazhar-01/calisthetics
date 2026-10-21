import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/paywall_offer.dart';
import '../domain/subscription.dart';

/// Thrown when a purchase does not go through (cancelled, store error).
class PurchaseFailure implements Exception {
  const PurchaseFailure(this.message, {this.cancelled = false});
  final String message;
  final bool cancelled;
  @override
  String toString() => message;
}

/// Buying and checking Premium. Two implementations:
///  * [RevenueCatSubscriptionService] once a RevenueCat key is set for the
///    platform (iOS is built in; Android: `--dart-define=
///    REVENUECAT_ANDROID_KEY=...`);
///  * [LocalSubscriptionService] until then: purchases succeed on the phone
///    without any payment, so the whole flow can be tried.
abstract class SubscriptionService {
  /// The last known status, available immediately (no network).
  SubscriptionStatus get cached;

  /// Fresh status (from the store when connected).
  Future<SubscriptionStatus> refresh();

  Future<List<PaywallOffer>> offers();

  Future<SubscriptionStatus> purchase(PremiumPlan plan);

  Future<SubscriptionStatus> restore();

  /// Ends the subscription. Only the local test store can do this; real
  /// subscriptions are cancelled in the App Store / Play Store.
  Future<SubscriptionStatus> cancel();

  bool get canCancelInApp;

  /// The signed-in account (null for a guest), so a subscription follows
  /// the account to other phones.
  Future<void> setAccount(String? uid);

  /// Whether real payments are connected.
  bool get isLive;
}

/// The status is kept under a `user_` key, so (like the rest of the user's
/// data) it is synced with their account and removed on sign-out.
const subscriptionPrefsKey = 'user_subscription';

SubscriptionStatus _readCache(SharedPreferences prefs) {
  final raw = prefs.getString(subscriptionPrefsKey);
  if (raw == null) return const SubscriptionStatus.free();
  try {
    return SubscriptionStatus.fromJson(
      Map<String, Object?>.from(jsonDecode(raw) as Map),
    );
  } catch (_) {
    return const SubscriptionStatus.free();
  }
}

Future<void> _writeCache(SharedPreferences prefs, SubscriptionStatus s) =>
    s.isPremium
    ? prefs.setString(subscriptionPrefsKey, jsonEncode(s.toJson()))
    : prefs.remove(subscriptionPrefsKey);

/// Test store: no payment, same behaviour as the real one. Monthly starts
/// with a 7-day trial and then renews monthly; yearly renews yearly.
class LocalSubscriptionService implements SubscriptionService {
  LocalSubscriptionService(
    this.prefs, {
    DateTime Function()? clock,
    this.allowPurchases = true,
  }) : _now = clock ?? DateTime.now;

  final SharedPreferences prefs;

  /// False in a release build made without RevenueCat keys: nobody may get
  /// Premium for free by accident.
  final bool allowPurchases;
  final DateTime Function() _now;

  static const trialDays = 7;

  @override
  bool get isLive => false;

  @override
  bool get canCancelInApp => allowPurchases;

  @override
  SubscriptionStatus get cached => allowPurchases
      ? _advance(_readCache(prefs))
      : const SubscriptionStatus.free();

  /// Moves the stored status to "now": an ended trial becomes the paid
  /// monthly plan; a passed renewal date rolls on (or ends if cancelled).
  SubscriptionStatus _advance(SubscriptionStatus s) {
    final plan = s.plan;
    if (plan == null) return s;
    final now = _now();
    var inTrial = s.inTrial;
    var renews = s.renewsAt;
    if (inTrial && s.trialEndsAt != null && !now.isBefore(s.trialEndsAt!)) {
      inTrial = false;
    }
    if (renews != null && !now.isBefore(renews)) {
      if (!s.willRenew) return const SubscriptionStatus.free();
      while (!now.isBefore(renews!)) {
        renews = plan == PremiumPlan.yearly
            ? DateTime(renews.year + 1, renews.month, renews.day)
            : DateTime(renews.year, renews.month + 1, renews.day);
      }
    }
    return SubscriptionStatus(
      plan: plan,
      inTrial: inTrial,
      trialEndsAt: s.trialEndsAt,
      renewsAt: renews,
      willRenew: s.willRenew,
    );
  }

  @override
  Future<SubscriptionStatus> refresh() async {
    final s = cached;
    await _writeCache(prefs, s);
    return s;
  }

  @override
  Future<List<PaywallOffer>> offers() async => defaultPaywallOffers;

  @override
  Future<SubscriptionStatus> purchase(PremiumPlan plan) async {
    if (!allowPurchases) {
      throw const PurchaseFailure(
        'Subscriptions are not available right now. Please try again later.',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final now = _now();
    final current = cached;
    // A trial is only for someone who has never had one on this account.
    final trial =
        plan == PremiumPlan.monthly && prefs.getBool(_trialUsedKey) != true;
    final SubscriptionStatus s;
    if (plan == PremiumPlan.yearly) {
      s = SubscriptionStatus(
        plan: plan,
        renewsAt: DateTime(now.year + 1, now.month, now.day),
      );
    } else if (trial) {
      final end = now.add(const Duration(days: trialDays));
      s = SubscriptionStatus(
        plan: plan,
        inTrial: true,
        trialEndsAt: end,
        renewsAt: end,
      );
    } else {
      s = SubscriptionStatus(
        plan: plan,
        renewsAt: current.plan == PremiumPlan.monthly
            ? current.renewsAt
            : DateTime(now.year, now.month + 1, now.day),
      );
    }
    if (trial) await prefs.setBool(_trialUsedKey, true);
    await _writeCache(prefs, s);
    return s;
  }

  static const _trialUsedKey = 'user_trial_used';

  @override
  Future<SubscriptionStatus> restore() => refresh();

  @override
  Future<SubscriptionStatus> cancel() async {
    await _writeCache(prefs, const SubscriptionStatus.free());
    return const SubscriptionStatus.free();
  }

  @override
  Future<void> setAccount(String? uid) async {}
}

/// RevenueCat: an entitlement named [entitlementId] unlocks Premium; the
/// current offering's monthly and annual packages are the two plans.
class RevenueCatSubscriptionService implements SubscriptionService {
  RevenueCatSubscriptionService(this.prefs, this.apiKey);

  final SharedPreferences prefs;
  final String apiKey;

  static const entitlementId = 'pro';

  /// RevenueCat's SDK keys are public keys made to ship inside the app (the
  /// secret `sk_` key must never be). `--dart-define` overrides the iOS one.
  static const _androidKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');
  static const iosKey = String.fromEnvironment(
    'REVENUECAT_IOS_KEY',
    defaultValue: 'appl_fwvaYbmjxPvSssHbyVBLhApShNZ',
  );

  /// The RevenueCat key for this platform, or null when not set.
  static String? platformKey() {
    if (kIsWeb) return null;
    final key = Platform.isIOS || Platform.isMacOS ? iosKey : _androidKey;
    return key.isEmpty ? null : key;
  }

  Future<void>? _ready;
  Future<void> _configure() => _ready ??= () async {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
    await Purchases.configure(PurchasesConfiguration(apiKey));
  }();

  @override
  bool get isLive => true;

  @override
  bool get canCancelInApp => false;

  @override
  SubscriptionStatus get cached => _readCache(prefs);

  SubscriptionStatus _fromInfo(CustomerInfo info) =>
      statusFromCustomerInfo(info);

  Future<SubscriptionStatus> _save(CustomerInfo info) async {
    final s = _fromInfo(info);
    await _writeCache(prefs, s);
    return s;
  }

  @override
  Future<SubscriptionStatus> refresh() async {
    try {
      await _configure();
      return await _save(await Purchases.getCustomerInfo());
    } catch (e) {
      debugPrint('RevenueCat refresh failed: $e');
      return cached;
    }
  }

  Future<Offering?> _offering() async {
    await _configure();
    return (await Purchases.getOfferings()).current;
  }

  /// The store's real offers. An empty list means the store could not be
  /// reached or has no products to show: the paywall then says so and lets
  /// the user retry, instead of showing prices that may not be real.
  @override
  Future<List<PaywallOffer>> offers() async {
    try {
      final o = await _offering();
      if (o == null) return const [];
      final monthly = o.monthly?.storeProduct;
      final annual = o.annual?.storeProduct;
      var monthlyTrial = monthly == null ? null : _trialDays(monthly);
      if (monthly != null && monthlyTrial != null && await _isApple) {
        // On iPhone the trial is offered once per Apple ID (per group): only
        // promise it when Apple says this user can still have it.
        monthlyTrial = await _trialStillAvailable(monthly)
            ? monthlyTrial
            : null;
      }
      return [
        if (monthly != null)
          PaywallOffer(
            plan: PremiumPlan.monthly,
            price: monthly.priceString,
            period: 'month',
            trialDays: monthlyTrial,
            amount: monthly.price,
          ),
        if (annual != null)
          PaywallOffer(
            plan: PremiumPlan.yearly,
            price: annual.priceString,
            period: 'year',
            perMonth: _perMonth(annual),
            amount: annual.price,
          ),
      ];
    } catch (e) {
      debugPrint('RevenueCat offerings failed: $e');
      return const [];
    }
  }

  static Future<bool> get _isApple async =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  static Future<bool> _trialStillAvailable(StoreProduct product) async {
    try {
      final result = await Purchases.checkTrialOrIntroductoryPriceEligibility([
        product.identifier,
      ]);
      return result[product.identifier]?.status ==
          IntroEligibilityStatus.introEligibilityStatusEligible;
    } catch (_) {
      return false; // not sure: do not promise it
    }
  }

  static int? _trialDays(StoreProduct p) {
    final intro = p.introductoryPrice;
    if (intro != null && intro.price == 0) {
      return switch (intro.periodUnit) {
        PeriodUnit.week => 7 * intro.periodNumberOfUnits,
        PeriodUnit.month => 30 * intro.periodNumberOfUnits,
        _ => intro.periodNumberOfUnits,
      };
    }
    final free = p.defaultOption?.freePhase?.billingPeriod;
    if (free == null) return null;
    return switch (free.unit) {
      PeriodUnit.week => 7 * free.value,
      PeriodUnit.month => 30 * free.value,
      _ => free.value,
    };
  }

  static String? _perMonth(StoreProduct p) {
    final m = p.pricePerMonthString;
    return (m == null || m.isEmpty) ? null : m;
  }

  @override
  Future<SubscriptionStatus> purchase(PremiumPlan plan) async {
    final o = await _offering();
    final package = plan == PremiumPlan.yearly ? o?.annual : o?.monthly;
    if (package == null) {
      throw const PurchaseFailure('This plan is not available right now.');
    }
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return await _save(result.customerInfo);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        throw const PurchaseFailure('Purchase cancelled.', cancelled: true);
      }
      throw PurchaseFailure(e.message ?? 'The purchase did not go through.');
    }
  }

  @override
  Future<SubscriptionStatus> restore() async {
    await _configure();
    return _save(await Purchases.restorePurchases());
  }

  @override
  Future<SubscriptionStatus> cancel() async => cached;

  @override
  Future<void> setAccount(String? uid) async {
    try {
      await _configure();
      if (uid == null) {
        if (!await Purchases.isAnonymous) await Purchases.logOut();
        await _writeCache(prefs, const SubscriptionStatus.free());
      } else {
        final r = await Purchases.logIn(uid);
        await _save(r.customerInfo);
      }
    } catch (e) {
      debugPrint('RevenueCat account switch failed: $e');
    }
  }
}

/// Whether [productId] is one of this app's Premium subscriptions.
bool _isOurProduct(String productId) =>
    productId.toLowerCase().contains('calisthenics_subscription');

PremiumPlan _planOf(String productId) {
  final id = productId.toLowerCase();
  return id.contains('year') || id.contains('annual')
      ? PremiumPlan.yearly
      : PremiumPlan.monthly;
}

/// What the customer has, from RevenueCat's customer info.
///
/// The `pro` entitlement decides. If it is not there (the products were
/// not attached to it in the RevenueCat dashboard, or it is named otherwise)
/// any other active entitlement counts, and failing that an active
/// subscription to one of this app's own products does: a paid purchase must
/// never leave the user on Free.
@visibleForTesting
SubscriptionStatus statusFromCustomerInfo(CustomerInfo info) {
  DateTime? date(String? v) =>
      v == null ? null : DateTime.tryParse(v)?.toLocal();

  final active = info.entitlements.active;
  final e =
      active[RevenueCatSubscriptionService.entitlementId] ??
      active.values.where((x) => x.isActive).firstOrNull;
  if (e != null && e.isActive) {
    final trial = e.periodType == PeriodType.trial;
    final expires = date(e.expirationDate);
    return SubscriptionStatus(
      plan: _planOf(e.productIdentifier),
      inTrial: trial,
      trialEndsAt: trial ? expires : null,
      renewsAt: expires,
      willRenew: e.willRenew,
    );
  }

  final ours = [
    for (final sub in info.subscriptionsByProductIdentifier.values)
      if (sub.isActive && _isOurProduct(sub.productIdentifier)) sub,
  ];
  if (ours.isNotEmpty) {
    final sub = ours.first;
    final trial = sub.periodType == PeriodType.trial;
    final expires = date(sub.expiresDate);
    debugPrint(
      'RevenueCat: ${sub.productIdentifier} is active but no entitlement '
      'carries it: attach it to the "${RevenueCatSubscriptionService.entitlementId}" entitlement.',
    );
    return SubscriptionStatus(
      plan: _planOf(sub.productIdentifier),
      inTrial: trial,
      trialEndsAt: trial ? expires : null,
      renewsAt: expires,
      willRenew: sub.willRenew,
    );
  }

  final id = info.activeSubscriptions.where(_isOurProduct).firstOrNull;
  if (id != null) {
    final expires = date(
      info.allExpirationDates[id] ?? info.latestExpirationDate,
    );
    return SubscriptionStatus(plan: _planOf(id), renewsAt: expires);
  }
  return const SubscriptionStatus.free();
}
