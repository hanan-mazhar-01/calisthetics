import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

const chapterNames = {1: 'Goal', 2: 'About you', 3: 'Fitness', 4: 'Your plan'};

/// Sticky header shown above every onboarding step except the full-bleed
/// welcome screen: a circular back button, the centered chapter title, and a
/// single continuous progress bar for position within the chapter — sits
/// directly on the onboarding flow's gradient wash (no background fill of
/// its own).
class OnboardingChrome extends StatelessWidget {
  const OnboardingChrome({
    super.key,
    required this.onBack,
    required this.chapter,
    required this.stepInChapter,
    required this.stepsInChapter,
  });

  final VoidCallback? onBack;
  final int chapter;
  final int stepInChapter;
  final int stepsInChapter;

  @override
  Widget build(BuildContext context) {
    final fraction = stepsInChapter == 0 ? 0.0 : stepInChapter / stepsInChapter;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              _BackButton(onTap: onBack),
              Expanded(
                child: Text(
                  chapterNames[chapter] ?? '',
                  textAlign: TextAlign.center,
                  style: AppTypography.title(
                    18,
                    context.appColors.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              width: double.infinity,
              height: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: context.appColors.surfaceMuted),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedFractionallySizedBox(
                      duration: AppDurations.stepTransition,
                      curve: AppCurves.standard,
                      widthFactor: fraction,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.appColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: context.appColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
