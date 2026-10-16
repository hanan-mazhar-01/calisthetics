import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/media_placeholder.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/onboarding_step.dart';

/// Full-bleed photo with an overlaid rhetorical question ("Story ·" screens).
/// Both buttons advance — like [StatementStepView], this is a beat for the
/// user to picture themselves there, not a real fork.
class PhotoQuestionStepView extends StatelessWidget {
  const PhotoQuestionStepView({
    super.key,
    required this.step,
    required this.onNext,
  });

  final PhotoQuestionStep step;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MediaPlaceholder(brief: step.photoPrompt),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.appColors.scrim(0.35),
                context.appColors.scrim(0),
                const Color(0xCC4A3035),
                const Color(0xFF4A3035),
              ],
              stops: const [0, 0.25, 0.5, 0.82],
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
              Text(
                'PICTURE THIS',
                style: AppTypography.kicker(
                  context.appColors.coverAccent,
                  letterSpacingEm: 0.12,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                step.question,
                style: AppTypography.display(
                  fontSize: 36,
                  color: context.appColors.onCover,
                  stretchPercent: 85,
                  height: 1.02,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 58,
                      child: Material(
                        color: context.appColors.onCover.withValues(
                          alpha: 0.16,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: onNext,
                          child: Center(
                            child: Text(
                              'Not yet',
                              style: AppTypography.title(
                                17,
                                Colors.white,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: "Yes, that's me",
                      onPressed: onNext,
                    ),
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
