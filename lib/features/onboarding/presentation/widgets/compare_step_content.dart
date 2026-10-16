import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/onboarding_step.dart';

/// Two-column "old way vs the Calesthetics way" panel: a muted outlined card for the old
/// way (each line crossed out), a dark elevated card for Calesthetics' way (each
/// line checked off) — the icon per row carries the argument, not just color.
class CompareStepContent extends StatelessWidget {
  const CompareStepContent({super.key, required this.step});

  final CompareStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.screenBottomCta,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: _CompareCard(
                kicker: 'OLD WAY',
                kickerColor: context.appColors.textMuted,
                items: step.leftItems,
                background: context.appColors.surface,
                border: context.appColors.divider,
                itemColor: context.appColors.textSecondary,
                markerColor: context.appColors.textMuted,
                markerIcon: Icons.close_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 7,
              child: _CompareCard(
                kicker: 'THE CALESTHETICS WAY',
                kickerColor: context.appColors.coverAccent,
                items: step.rightItems,
                background: context.appColors.cover,
                itemColor: context.appColors.onCover,
                itemWeight: FontWeight.w600,
                markerColor: context.appColors.accent,
                markerIcon: Icons.check_rounded,
                elevated: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({
    required this.kicker,
    required this.kickerColor,
    required this.items,
    required this.background,
    required this.itemColor,
    required this.markerColor,
    required this.markerIcon,
    this.border,
    this.itemWeight = FontWeight.w500,
    this.elevated = false,
  });

  final String kicker;
  final Color kickerColor;
  final List<String> items;
  final Color background;
  final Color? border;
  final Color itemColor;
  final Color markerColor;
  final IconData markerIcon;
  final FontWeight itemWeight;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(28),
        border: border != null ? Border.all(color: border!, width: 1.5) : null,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: context.appColors.cover.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: AppTypography.kicker(
              kickerColor,
              fontSize: 12.5,
              letterSpacingEm: 0.08,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < items.length; i++) ...[
            if (i != 0) const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: markerColor.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(markerIcon, size: 12, color: markerColor),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    items[i],
                    style: AppTypography.body(
                      itemColor,
                      fontSize: 14.5,
                      weight: itemWeight,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
