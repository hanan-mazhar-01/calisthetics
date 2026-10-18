/// The two ways to buy Premium. Free keeps one plan; Premium unlocks every
/// plan and every Discover exercise.
enum PremiumPlan { monthly, yearly }

/// What the user has right now.
class SubscriptionStatus {
  const SubscriptionStatus({
    this.plan,
    this.inTrial = false,
    this.trialEndsAt,
    this.renewsAt,
    this.willRenew = true,
  });

  const SubscriptionStatus.free() : this();

  /// Null when on the free tier.
  final PremiumPlan? plan;

  /// Inside the monthly plan's 7-day free trial.
  final bool inTrial;
  final DateTime? trialEndsAt;

  /// Next charge (or the end, when [willRenew] is false).
  final DateTime? renewsAt;
  final bool willRenew;

  bool get isPremium => plan != null;

  /// Whole days left in the trial (at least 1 while it runs).
  int trialDaysLeft(DateTime now) {
    final end = trialEndsAt;
    if (!inTrial || end == null) return 0;
    final hours = end.difference(now).inHours;
    return hours <= 0 ? 0 : (hours / 24).ceil();
  }

  Map<String, Object?> toJson() => {
    'plan': plan?.name,
    'inTrial': inTrial,
    'trialEndsAt': trialEndsAt?.toIso8601String(),
    'renewsAt': renewsAt?.toIso8601String(),
    'willRenew': willRenew,
  };

  factory SubscriptionStatus.fromJson(Map<String, Object?> json) {
    DateTime? date(Object? v) => v is String ? DateTime.tryParse(v) : null;
    final name = json['plan'];
    return SubscriptionStatus(
      plan: PremiumPlan.values.where((p) => p.name == name).firstOrNull,
      inTrial: json['inTrial'] == true,
      trialEndsAt: date(json['trialEndsAt']),
      renewsAt: date(json['renewsAt']),
      willRenew: json['willRenew'] != false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SubscriptionStatus &&
      other.plan == plan &&
      other.inTrial == inTrial &&
      other.trialEndsAt == trialEndsAt &&
      other.renewsAt == renewsAt &&
      other.willRenew == willRenew;

  @override
  int get hashCode =>
      Object.hash(plan, inTrial, trialEndsAt, renewsAt, willRenew);
}
