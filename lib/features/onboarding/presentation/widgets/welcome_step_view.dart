import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/media_placeholder.dart';
import '../../../../shared/widgets/primary_button.dart';

/// Screen 1: full-bleed dark cover — the only onboarding screen with no
/// chrome header, matching the reference's cinematic first impression.
class WelcomeStepView extends StatelessWidget {
  const WelcomeStepView({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: context.appColors.cover),
        // Bottom inset keeps the placeholder label clear of the headline;
        // it is dimmed so the white headline stays legible in light theme.
        const Positioned.fill(
          bottom: 420,
          child: Opacity(
            opacity: 0.3,
            child: MediaPlaceholder(
              brief: 'Hero video: woman holding a strong push-up plank, warm studio light',
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.appColors.scrim(0.25),
                context.appColors.scrim(0),
                context.appColors.scrim(0.55),
                context.appColors.cover,
              ],
              stops: const [0, 0.3, 0.58, 0.86],
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.xxxl,
          right: AppSpacing.xxxl,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 2,
                    color: context.appColors.coverAccent,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    "CALESTHETICS FOR WOMEN",
                    style: AppTypography.kicker(
                      context.appColors.coverAccent,
                      letterSpacingEm: 0.14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              RichText(
                text: TextSpan(
                  style: AppTypography.display(
                    fontSize: 48,
                    color: context.appColors.onCover,
                    stretchPercent: 78,
                  ),
                  children: [
                    const TextSpan(text: 'Build strength.\n'),
                    TextSpan(
                      text: 'Master',
                      style: AppTypography.display(
                        fontSize: 48,
                        color: context.appColors.coverAccent,
                        stretchPercent: 78,
                      ),
                    ),
                    const TextSpan(text: ' your body.'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Four-week plans that build from the basics toward real calisthenics skills, one phase at a time.',
                style: AppTypography.body(context.appColors.onCoverTertiary),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: context.appColors.onCover.withValues(alpha: 0.18),
                    ),
                    bottom: BorderSide(
                      color: context.appColors.onCover.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                child: Row(
                  children: const [
                    _Stat(value: '8', caption: 'Skills'),
                    SizedBox(width: AppSpacing.xxxl),
                    _Stat(value: '115', caption: 'Exercises'),
                    SizedBox(width: AppSpacing.xxxl),
                    _Stat(value: '98', caption: 'Coached videos'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: 'Start my journey',
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: onStart,
              ),
              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Log in will be available once accounts are connected.',
                      ),
                    ),
                  ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text.rich(
                    TextSpan(
                      style: AppTypography.body(
                        context.appColors.onCoverSecondary,
                        fontSize: 14,
                      ),
                      children: [
                        const TextSpan(text: 'Already training with us? '),
                        TextSpan(
                          text: 'Log in',
                          style: TextStyle(
                            color: context.appColors.onCover,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.caption});

  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.title(
            22,
            context.appColors.onCover,
            weight: FontWeight.w800,
          ),
        ),
        Text(
          caption,
          style: AppTypography.body(
            context.appColors.onCoverSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
