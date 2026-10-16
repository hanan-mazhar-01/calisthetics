import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/primary_button.dart';

/// Optional account creation. Sign-in is not connected yet (no auth backend),
/// so the three methods are shown disabled with a "Coming soon" label and
/// Skip is the one working action.
class AccountStepView extends StatelessWidget {
  const AccountStepView({
    super.key,
    required this.onSkip,
    required this.onBack,
    this.busy = false,
  });

  final VoidCallback onSkip;
  final VoidCallback onBack;

  /// True while the plan is being started after Skip.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    const methods = [
      (Icons.apple_rounded, 'Continue with Apple'),
      (Icons.g_mobiledata_rounded, 'Continue with Google'),
      (Icons.mail_outline_rounded, 'Continue with email'),
    ];
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GlassButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: 'Back',
                      onPressed: onBack,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: busy ? null : onSkip,
                      child: Text(
                        'Skip',
                        style: AppTypography.title(
                          16,
                          c.accentText,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  'Save your plan.',
                  style: AppTypography.display(
                    fontSize: 36,
                    color: c.textPrimary,
                    stretchPercent: 82,
                    height: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'An account would keep your plan and progress safe if you change phones. It is optional.',
                  style: AppTypography.body(c.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                for (final (icon, label) in methods)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Opacity(
                      opacity: 0.55,
                      child: GlassCard(
                        child: Row(
                          children: [
                            Icon(icon, color: c.textPrimary),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Text(
                                label,
                                style: AppTypography.title(
                                  16,
                                  c.textPrimary,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              'Coming soon',
                              style: AppTypography.kicker(
                                c.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Accounts are not connected yet. Your plan is stored on this device for now.',
                  style: AppTypography.body(c.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxxl,
            0,
            AppSpacing.xxxl,
            AppSpacing.xxl,
          ),
          child: PrimaryButton(
            label: 'Skip and start my plan',
            enabled: !busy,
            onPressed: busy ? null : onSkip,
            trailingIcon: Icons.arrow_forward_rounded,
          ),
        ),
      ],
    );
  }
}
