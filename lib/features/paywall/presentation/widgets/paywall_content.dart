import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/bunny_image.dart';
import '../../../exercises/data/exercise_catalog.dart';
import '../../../plans/data/plan_templates.dart';
import '../../data/subscription_service.dart';
import '../../domain/paywall_offer.dart';
import '../../domain/subscription.dart';
import '../providers/subscription_providers.dart';

const _pinkA = Color(0xFFFF7E98);
const _pinkB = Color(0xFFEF5B82);

/// The paywall (route `/paywall` and the onboarding step): what Premium
/// unlocks, Monthly with a 7-day free trial or Yearly, and the buy button.
///
/// [onClose] is the X and "Continue with Free": the user keeps the free
/// tier (one plan). After a purchase a short "welcome" screen shows, then
/// [onClose] runs too.
class PaywallContent extends ConsumerStatefulWidget {
  const PaywallContent({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<PaywallContent> createState() => _PaywallContentState();
}

class _PaywallContentState extends ConsumerState<PaywallContent> {
  PremiumPlan _choice = PremiumPlan.monthly;
  bool _busy = false;
  SubscriptionStatus? _bought;

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _buy() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      final s = await ref.read(subscriptionProvider.notifier).purchase(_choice);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => _bought = s);
    } on PurchaseFailure catch (e) {
      if (mounted && !e.cancelled) _say(e.message);
    } catch (e) {
      if (mounted) _say('The purchase did not go through. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      final s = await ref.read(subscriptionProvider.notifier).restore();
      if (!mounted) return;
      if (s.isPremium) {
        setState(() => _bought = s);
      } else {
        _say('No active subscription was found.');
      }
    } catch (_) {
      if (mounted) _say('Could not restore purchases. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final offers =
        ref.watch(paywallOffersProvider).asData?.value ?? defaultPaywallOffers;
    final current = ref.watch(subscriptionProvider);
    final chosen =
        offers.where((o) => o.plan == _choice).firstOrNull ?? offers.first;
    final trial = chosen.trialDays;
    // Someone already on Premium does not get a second trial.
    final showTrial = trial != null && !current.isPremium;

    final cta = current.plan == _choice
        ? 'Your current plan'
        : showTrial
        ? 'Start my $trial-day free trial'
        : 'Continue · ${chosen.price}/${chosen.period}';
    final fine = showTrial
        ? 'Free for $trial days, then ${chosen.price}/${chosen.period}. '
              'Cancel any time.'
        : 'Billed ${chosen.price} every ${chosen.period}. Cancel any time.';

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Hero(onClose: widget.onClose),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              style: AppTypography.title(
                                26,
                                c.textPrimary,
                                weight: FontWeight.w600,
                                height: 1.15,
                              ),
                              children: [
                                const TextSpan(text: 'Unlock your full '),
                                TextSpan(
                                  text: 'journey',
                                  style: AppTypography.accentSerif(
                                    c.accentText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your first plan is free. Go Premium to train '
                            'with every plan and the whole exercise library.',
                            style: AppTypography.body(
                              c.textSecondary,
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _Feature(
                            index: 0,
                            title: 'Every plan, as many as you want',
                            note: 'Free keeps one plan',
                          ),
                          _Feature(
                            index: 1,
                            title:
                                'All ${exerciseCatalog.length} Discover exercises',
                            note: 'With video coaching for each one',
                          ),
                          const _Feature(
                            index: 2,
                            title: 'Full skill ladders',
                            note: 'Push-up, pull-up, handstand and more',
                          ),
                          const _Feature(
                            index: 3,
                            title: 'Switch plans any time',
                            note: 'Your progress stays with you',
                          ),
                          const SizedBox(height: 18),
                          for (final o in offers)
                            _OfferCard(
                              offer: o,
                              selected: o.plan == _choice,
                              current: current.plan == o.plan,
                              showTrial: !current.isPremium,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _choice = o.plan);
                              },
                            ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: showTrial
                                ? _TrialTimeline(
                                    days: trial,
                                    price: '${chosen.price}/${chosen.period}',
                                  )
                                : const SizedBox(width: double.infinity),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: c.softRose.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text.rich(
                              TextSpan(
                                style: AppTypography.body(
                                  c.textPrimary,
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                                children: const [
                                  TextSpan(text: 'Not now? You keep '),
                                  TextSpan(
                                    text: 'one free plan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        ', and you can upgrade any time from '
                                        'your profile.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BuyButton(
                    label: cta,
                    busy: _busy,
                    onTap: current.plan == _choice ? null : _buy,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fine,
                    textAlign: TextAlign.center,
                    style: AppTypography.body(c.textSecondary, fontSize: 12),
                  ),
                  if (!ref.read(subscriptionServiceProvider).isLive)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Test mode: no payment is taken.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body(c.textMuted, fontSize: 11),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      _LinkButton(
                        label: 'Continue with Free',
                        onTap: widget.onClose,
                      ),
                      _LinkButton(label: 'Restore', onTap: _restore),
                      _LinkButton(
                        label: 'Terms',
                        onTap: () => _say('The Terms link is coming soon.'),
                      ),
                      _LinkButton(
                        label: 'Privacy',
                        onTap: () =>
                            _say('The Privacy Policy link is coming soon.'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_bought != null)
          Positioned.fill(
            child: _Welcome(status: _bought!, onDone: widget.onClose),
          ),
      ],
    );
  }
}

/// Photo on a rose wash, the PREMIUM badge, the X and three floating chips.
class _Hero extends StatelessWidget {
  const _Hero({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final chip = [
      (Icons.star_rounded, '${planTemplates.length} plans'),
      (Icons.play_arrow_rounded, '${exerciseCatalog.length} exercises'),
      (Icons.trending_up_rounded, 'Skill ladders'),
    ];
    return SizedBox(
      height: 236,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [c.softRose, c.background],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: -4,
            height: 222,
            child: _Rise(
              child: BunnyImage(
                'onboarding/your-plan/after',
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'PREMIUM',
                style: AppTypography.kicker(
                  c.accentText,
                  letterSpacingEm: 0.14,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 14,
            child: Semantics(
              button: true,
              label: 'Close',
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.surface.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          for (final (i, pos) in const [
            (0, Offset(14, 92)),
            (1, Offset(-12, 128)),
            (2, Offset(20, 170)),
          ].indexed)
            Positioned(
              top: pos.$2.dy,
              left: pos.$2.dx >= 0 ? pos.$2.dx : null,
              right: pos.$2.dx < 0 ? -pos.$2.dx : null,
              child: _Pop(
                delay: Duration(milliseconds: 350 + 150 * i),
                child: _Chip(icon: chip[pos.$1].$1, label: chip[pos.$1].$2),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: c.softRose,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: c.accentText),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.title(
              12.5,
              c.textPrimary,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A gradient tick and a feature with its note, fading in one by one.
class _Feature extends StatelessWidget {
  const _Feature({
    required this.index,
    required this.title,
    required this.note,
  });

  final int index;
  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return _Pop(
      delay: Duration(milliseconds: 450 + 100 * index),
      scale: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(
          children: [
            const _Tick(size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.title(
                      14.5,
                      c.textPrimary,
                      weight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    note,
                    style: AppTypography.body(c.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  const _Tick({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_pinkA, _pinkB],
        ),
      ),
      child: Icon(Icons.check_rounded, size: size * 0.62, color: Colors.white),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.selected,
    required this.current,
    required this.showTrial,
    required this.onTap,
  });

  final PaywallOffer offer;
  final bool selected;
  final bool current;
  final bool showTrial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final yearly = offer.plan == PremiumPlan.yearly;
    final tag = current
        ? 'CURRENT'
        : yearly
        ? 'SAVE 58%'
        : (offer.trialDays != null && showTrial)
        ? '${offer.trialDays} DAYS FREE'
        : null;
    final meta = yearly
        ? (offer.perMonth != null ? '${offer.perMonth} / month' : 'Best value')
        : (offer.trialDays != null && showTrial)
        ? '${offer.trialDays}-day free trial'
        : 'Billed monthly';
    return Semantics(
      button: true,
      selected: selected,
      label: '${offer.title}, ${offer.price} per ${offer.period}. $meta',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selected ? c.accent : c.divider,
                    width: 2,
                  ),
                  boxShadow: [
                    if (selected)
                      BoxShadow(
                        color: c.accent.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? c.accent : Colors.transparent,
                        border: Border.all(
                          color: selected ? c.accent : c.textMuted,
                          width: 2,
                        ),
                      ),
                      child: AnimatedScale(
                        scale: selected ? 1 : 0.3,
                        duration: const Duration(milliseconds: 250),
                        child: AnimatedOpacity(
                          opacity: selected ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.title,
                            style: AppTypography.title(
                              16,
                              c.textPrimary,
                              weight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            meta,
                            style: AppTypography.body(
                              c.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          offer.price,
                          style: AppTypography.title(
                            17,
                            c.textPrimary,
                            weight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'per ${offer.period}',
                          style: AppTypography.body(
                            c.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (tag != null)
                Positioned(
                  top: -10,
                  right: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: yearly && !current ? c.softRose : null,
                      gradient: yearly && !current
                          ? null
                          : const LinearGradient(colors: [_pinkA, _pinkB]),
                    ),
                    child: Text(
                      tag,
                      style: AppTypography.title(
                        10.5,
                        yearly && !current ? c.accentText : Colors.white,
                        weight: FontWeight.w600,
                      ).copyWith(letterSpacing: 0.8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "How your free trial works": today, the reminder, the first charge.
class _TrialTimeline extends StatelessWidget {
  const _TrialTimeline({required this.days, required this.price});

  final int days;
  final String price;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final steps = [
      (Icons.lock_open_rounded, 'Today', 'Everything unlocks. No charge.'),
      (
        Icons.notifications_none_rounded,
        'Day ${math.max(1, days - 2)}',
        'We remind you that the trial is ending.',
      ),
      (
        Icons.star_rounded,
        'Day $days',
        '$price starts. Cancel any time before.',
      ),
    ];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How your free trial works',
            style: AppTypography.title(
              14,
              c.textPrimary,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          for (final (i, s) in steps.indexed)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0 ? c.accent : c.softRose,
                        ),
                        child: Icon(
                          s.$1,
                          size: 15,
                          color: i == 0 ? c.onAccent : c.accentText,
                        ),
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [c.accent, c.softRose],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14, top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.$2,
                            style: AppTypography.title(
                              13.5,
                              c.textPrimary,
                              weight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            s.$3,
                            style: AppTypography.body(
                              c.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The gradient buy button with a passing shine and a spinner while busy.
class _BuyButton extends StatefulWidget {
  const _BuyButton({required this.label, required this.busy, this.onTap});

  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  State<_BuyButton> createState() => _BuyButtonState();
}

class _BuyButtonState extends State<_BuyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _shine.stop();
    } else if (!_shine.isAnimating) {
      _shine.repeat();
    }
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.busy;
    final c = context.appColors;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.onTap == null ? 0.55 : 1,
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: LinearGradient(colors: [_pinkA, _pinkB, c.accent]),
              boxShadow: [
                BoxShadow(
                  color: _pinkB.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (enabled)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _shine,
                      builder: (context, _) {
                        // Sweeps across in the last 40% of each cycle.
                        final t = ((_shine.value - 0.6) / 0.4).clamp(0.0, 1.0);
                        return FractionalTranslation(
                          translation: Offset(-1 + 2 * t, 0),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0x00FFFFFF),
                                  Color(0x55FFFFFF),
                                  Color(0x00FFFFFF),
                                ],
                                stops: [0.3, 0.5, 0.7],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                widget.busy
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.label,
                        style: AppTypography.title(
                          17,
                          Colors.white,
                          weight: FontWeight.w600,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// After buying: a big tick, falling confetti and what is unlocked now.
class _Welcome extends StatefulWidget {
  const _Welcome({required this.status, required this.onDone});

  final SubscriptionStatus status;
  final VoidCallback onDone;

  @override
  State<_Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<_Welcome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();
  final _confetti = List.generate(36, (i) => math.Random(i));

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final s = widget.status;
    final trial = s.inTrial;
    final days = s.trialDaysLeft(DateTime.now());
    final colors = [
      _pinkA,
      _pinkB,
      c.softRose,
      const Color(0xFFFFD27A),
      c.accent,
    ];
    return AnimatedBuilder(
      animation: _a,
      builder: (context, _) {
        final t = _a.value;
        final pop = Curves.elasticOut.transform((t / 0.45).clamp(0.0, 1.0));
        return Opacity(
          opacity: (t / 0.12).clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.25),
                radius: 0.9,
                colors: [c.softRose, c.background],
              ),
            ),
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, box) => Stack(
                    children: [
                      for (final (i, r) in _confetti.indexed)
                        Positioned(
                          left: box.maxWidth * ((i * 37 % 100) / 100),
                          top:
                              -20 +
                              (box.maxHeight + 40) *
                                  Curves.easeIn.transform(
                                    ((t - (i % 6) * 0.04) *
                                            (1.1 + (i % 4) * 0.12))
                                        .clamp(0.0, 1.0),
                                  ),
                          child: Transform.rotate(
                            angle: t * 9 * (i.isEven ? 1 : -1) + r.nextDouble(),
                            child: Container(
                              width: 8,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[i % colors.length],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: pop,
                          child: Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [_pinkA, _pinkB],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _pinkB.withValues(alpha: 0.35),
                                  blurRadius: 40,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 58,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Text.rich(
                          textAlign: TextAlign.center,
                          TextSpan(
                            style: AppTypography.title(
                              26,
                              c.textPrimary,
                              weight: FontWeight.w600,
                            ),
                            children: trial
                                ? [
                                    const TextSpan(text: 'Your free trial '),
                                    TextSpan(
                                      text: 'has started',
                                      style: AppTypography.accentSerif(
                                        c.accentText,
                                      ),
                                    ),
                                  ]
                                : [
                                    const TextSpan(text: 'Welcome to '),
                                    TextSpan(
                                      text: 'Premium',
                                      style: AppTypography.accentSerif(
                                        c.accentText,
                                      ),
                                    ),
                                  ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          trial
                              ? 'Every plan and all ${exerciseCatalog.length} '
                                    'exercises are unlocked. Your trial ends '
                                    'in $days days.'
                              : 'Every plan and all ${exerciseCatalog.length} '
                                    'exercises are unlocked.',
                          textAlign: TextAlign.center,
                          style: AppTypography.body(
                            c.textSecondary,
                            fontSize: 14.5,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _BuyButton(
                          label: "Let's train",
                          busy: false,
                          onTap: widget.onDone,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 36),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: AppTypography.body(
          context.appColors.textSecondary,
          fontSize: 12.5,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Rises in from below on first show.
class _Rise extends StatelessWidget {
  const _Rise({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}

/// Fades (and pops, when [scale]) in after [delay].
class _Pop extends StatelessWidget {
  const _Pop({required this.child, required this.delay, this.scale = true});
  final Widget child;
  final Duration delay;
  final bool scale;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final total = delay + const Duration(milliseconds: 550);
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      child: child,
      builder: (context, v, child) {
        final t = ((v - start) / (1 - start)).clamp(0.0, 1.0);
        final curved = (scale ? Curves.easeOutBack : Curves.easeOut).transform(
          t,
        );
        return Opacity(
          opacity: t,
          child: scale
              ? Transform.scale(scale: 0.6 + 0.4 * curved, child: child)
              : Transform.translate(
                  offset: Offset(0, 8 * (1 - curved)),
                  child: child,
                ),
        );
      },
    );
  }
}
