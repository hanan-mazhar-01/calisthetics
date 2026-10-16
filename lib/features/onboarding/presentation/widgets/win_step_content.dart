import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/media_placeholder.dart';
import '../../domain/onboarding_plan_summary.dart';

/// Body for the single "Encouragement" milestone screen: a reassurance
/// photo plus a supporting stat, sitting under the shared chrome/titled
/// header like any other choice/curve step.
class WinStepContent extends StatelessWidget {
  const WinStepContent({super.key, this.plan});

  /// Real figures for the chosen plan; null only if no plan was chosen.
  final OnboardingPlanSummary? plan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        0,
        AppSpacing.xxxl,
        AppSpacing.screenBottomCta,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: MediaPlaceholder(
                brief: plan == null
                    ? 'Woman training, smiling'
                    : 'Hero image: ${plan!.template.name}',
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.xxl),
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: context.appColors.textPrimary, width: 2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppTypography.display(
                      fontSize: 64,
                      color: context.appColors.accent,
                      stretchPercent: 65,
                      height: 0.9,
                    ),
                    children: [
                      TextSpan(text: '${plan?.cycleDays ?? 28}'),
                      const TextSpan(
                        text: 'DAYS',
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: Text(
                    plan == null
                        ? 'Your first four weeks, laid out for you.'
                        : 'Your first cycle: ${plan!.sessionsPerWeek} sessions a week, ${plan!.minutesLabel} each, with rest days built in.',
                    style: AppTypography.body(context.appColors.textSecondary),
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
