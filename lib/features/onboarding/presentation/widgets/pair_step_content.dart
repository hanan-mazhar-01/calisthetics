import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/bunny_image.dart';
import '../../../../shared/widgets/media_placeholder.dart';

/// Emotional-benefit screen: two contrasted weeks side by side, then a
/// grounding paragraph. Copy is fixed — there's only one screen of this kind.
class PairStepContent extends StatelessWidget {
  const PairStepContent({super.key});

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Panel(
                  photoPrompt: 'Starting out: hesitant first push-up',
                  imageKey: 'onboarding/your-plan/before',
                  grayscale: true,
                  weekLabel: 'Starting out',
                  weekColor: context.appColors.textPrimary,
                  caption: 'Unsure where to start',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Panel(
                  photoPrompt: 'With practice: confident, strong plank',
                  imageKey: 'onboarding/your-plan/after',
                  grayscale: false,
                  weekLabel: 'With practice',
                  weekColor: context.appColors.accent,
                  caption: 'Owning every rep',
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.xxl),
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: context.appColors.divider, width: 2),
              ),
            ),
            child: Text(
              'Strength training can make everyday things feel easier — carrying groceries, climbing stairs, holding your posture.',
              style: AppTypography.body(
                context.appColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.photoPrompt,
    required this.imageKey,
    required this.grayscale,
    required this.weekLabel,
    required this.weekColor,
    required this.caption,
  });

  final String photoPrompt;
  final String imageKey;
  final bool grayscale;
  final String weekLabel;
  final Color weekColor;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 250,
            child: ColorFiltered(
              colorFilter: grayscale
                  ? const ColorFilter.matrix(<double>[
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ])
                  : const ColorFilter.mode(
                      Colors.transparent,
                      BlendMode.multiply,
                    ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      context.appColors.softRose,
                      context.appColors.surfaceMuted,
                    ],
                  ),
                ),
                child: BunnyImage(
                  imageKey,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  fallback: MediaPlaceholder(brief: photoPrompt),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          weekLabel,
          style: AppTypography.title(17, weekColor, weight: FontWeight.w800),
        ),
        Text(
          caption,
          style: AppTypography.body(
            context.appColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
