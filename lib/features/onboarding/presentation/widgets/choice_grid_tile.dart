import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/media_placeholder.dart';
import '../../domain/onboarding_step.dart';

/// A photo tile in a grid-choice step: full-bleed media with a solid
/// caption bar across the bottom (label centered, description under it when
/// present) and a corner checkmark badge once selected. Sized purely by the
/// grid's aspect ratio, never a fixed pixel height, so it scales cleanly
/// across phone widths.
class ChoiceGridTile extends StatelessWidget {
  const ChoiceGridTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ChoiceOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.015 : 1,
        duration: AppDurations.selection,
        curve: AppCurves.standard,
        child: AnimatedContainer(
          duration: AppDurations.selection,
          curve: AppCurves.standard,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? context.appColors.accent : Colors.transparent,
              width: 3,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MediaPlaceholder(brief: option.imagePrompt ?? option.label),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    color: context.appColors.cover.withValues(alpha: 0.55),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          option.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title(
                            16,
                            Colors.white,
                            weight: FontWeight.w800,
                          ),
                        ),
                        if (option.description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            option.description!,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body(
                              context.appColors.softRose,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: AppDurations.selection,
                    curve: AppCurves.overshoot,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: context.appColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: context.appColors.onAccent,
                      ),
                    ),
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
