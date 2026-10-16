import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/onboarding_step.dart';

/// Shared headline+subtitle block rendered under the chrome header on every
/// choice/curve step (the middle headline segment renders in brand rose).
class OnboardingTitledHeader extends StatelessWidget {
  const OnboardingTitledHeader({
    super.key,
    required this.headline,
    this.subtitle,
  });

  final Headline headline;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        AppSpacing.sm,
        AppSpacing.xxxl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: AppTypography.display(
                fontSize: 32,
                color: context.appColors.textPrimary,
                stretchPercent: 85,
                letterSpacingEm: -0.02,
              ),
              children: [
                TextSpan(text: headline.lead),
                TextSpan(
                  text: headline.accent,
                  style: TextStyle(color: context.appColors.accentText),
                ),
                TextSpan(text: headline.tail),
              ],
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              subtitle!,
              style: AppTypography.body(context.appColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
