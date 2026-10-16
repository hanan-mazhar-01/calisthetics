import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../plans/data/plan_templates.dart';
import '../../domain/paywall_offer.dart';

/// The single paywall body: premium intro and free-vs-premium on one screen.
/// Used by the `/paywall` route and as the last-but-one onboarding step.
///
/// [onClose] is the visible X (and the "continue with Free" link): both lead
/// to the free tier. Purchasing and restoring are not connected yet, so the
/// buy button stays disabled and says why; nothing here invents a price.
class PaywallContent extends ConsumerStatefulWidget {
  const PaywallContent({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<PaywallContent> createState() => _PaywallContentState();
}

class _PaywallContentState extends ConsumerState<PaywallContent> {
  String? _selectedOfferId;

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final offers = ref.watch(paywallOffersProvider);
    final selected = offers.offers.any((o) => o.id == _selectedOfferId)
        ? _selectedOfferId
        : offers.offers.firstOrNull?.id;
    final chosen = [
      for (final o in offers.offers)
        if (o.id == selected) o,
    ].firstOrNull;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.sm,
              AppSpacing.xxl,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: GlassButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Close',
                    onPressed: widget.onClose,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'CALESTHETICS PREMIUM',
                  style: AppTypography.kicker(
                    c.accentText,
                    letterSpacingEm: 0.12,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Train with every plan.',
                  style: AppTypography.display(
                    fontSize: 36,
                    color: c.textPrimary,
                    stretchPercent: 82,
                    height: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Start free with one plan. Premium opens every plan, with your own preferences on each.',
                  style: AppTypography.body(c.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _ComparisonCard(planCount: planTemplates.length),
                const SizedBox(height: AppSpacing.xxl),
                _OffersSection(
                  offers: offers,
                  selectedId: selected,
                  onSelect: (id) => setState(() => _selectedOfferId = id),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.sm,
            AppSpacing.xxl,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(
                label: chosen?.trialLabel == null
                    ? 'Start free trial'
                    : 'Start ${chosen!.trialLabel}',
                enabled: false,
                onPressed: null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                offers.isAvailable ? 'Purchases are not connected yet.' : 'Trial length and price will be shown here, from the store, before you subscribe. You can cancel any time in your store account.',
                textAlign: TextAlign.center,
                style: AppTypography.body(c.textMuted, fontSize: 12.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _LinkButton(
                    label: 'Continue with Free',
                    onTap: widget.onClose,
                  ),
                  _LinkButton(
                    label: 'Restore Purchases',
                    onTap: () => _say(
                      'Restoring purchases will work once subscriptions are connected.',
                    ),
                  ),
                  _LinkButton(
                    label: 'Privacy Policy',
                    onTap: () =>
                        _say('The Privacy Policy link is coming soon.'),
                  ),
                  _LinkButton(
                    label: 'Terms',
                    onTap: () => _say('The Terms link is coming soon.'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: AppTypography.body(
          context.appColors.textSecondary,
          fontSize: 13,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.planCount});

  final int planCount;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final rows = [
      ('Active plans', '1', 'All $planCount'),
      ('Switch plans any time', '—', 'Yes'),
    ];
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(flex: 5, child: SizedBox()),
              Expanded(
                flex: 3,
                child: Text(
                  'FREE',
                  textAlign: TextAlign.center,
                  style: AppTypography.kicker(c.textSecondary),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'PREMIUM',
                  textAlign: TextAlign.center,
                  style: AppTypography.kicker(c.accentText),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final (label, free, premium) in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      label,
                      style: AppTypography.title(
                        15,
                        c.textPrimary,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      free,
                      textAlign: TextAlign.center,
                      style: AppTypography.body(c.textSecondary, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      premium,
                      textAlign: TextAlign.center,
                      style: AppTypography.body(
                        c.accentText,
                        fontSize: 13,
                        weight: FontWeight.w700,
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

class _OffersSection extends StatelessWidget {
  const _OffersSection({
    required this.offers,
    required this.selectedId,
    required this.onSelect,
  });

  final PaywallOffers offers;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    if (!offers.isAvailable) {
      return GlassCard(
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: c.textMuted),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                'Prices will appear here once subscriptions are connected.',
                style: AppTypography.body(c.textSecondary, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final o in offers.offers)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: GlassCard(
              selected: o.id == selectedId,
              onTap: () => onSelect(o.id),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.title,
                          style: AppTypography.title(16, c.textPrimary),
                        ),
                        if (o.trialLabel != null)
                          Text(
                            o.trialLabel!,
                            style: AppTypography.body(
                              c.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    o.priceLabel,
                    style: AppTypography.title(16, c.textPrimary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
