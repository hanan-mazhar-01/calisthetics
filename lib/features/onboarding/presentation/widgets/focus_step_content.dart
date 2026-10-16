import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/media_placeholder.dart';
import '../../domain/onboarding_step.dart';
import '../providers/onboarding_controller.dart';
import 'choice_step_content.dart';

/// Body-silhouette multi-select: tappable pills positioned fractionally over
/// a figure placeholder, matching the reference's absolute-positioned map.
class FocusStepContent extends ConsumerWidget {
  const FocusStepContent({super.key, required this.step, this.binding});

  final FocusStep step;
  final SelectionBinding? binding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final Set<String> selected =
        binding?.selected ??
        ref.watch(
          onboardingControllerProvider.select(
            (s) => s.selections[step.id] ?? const <String>{},
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.screenBottomCta,
      ),
      child: SizedBox(
        height: 560,
        child: Stack(
          children: [
            Positioned(
              left: 80,
              right: 80,
              top: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(120),
                  bottom: Radius.circular(24),
                ),
                child: const MediaPlaceholder(
                  brief:
                      'Full-length athletic woman, front view, neutral stance',
                ),
              ),
            ),
            for (var i = 0; i < step.areas.length; i++)
              _FocusPill(
                area: step.areas[i],
                selected: selected.contains(step.areas[i].id),
                onTap: () => binding != null
                    ? binding!.onToggle(step.areas[i].id)
                    : controller.toggleOption(
                        step.id,
                        step.areas[i].id,
                        multi: true,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FocusPill extends StatelessWidget {
  const _FocusPill({
    required this.area,
    required this.selected,
    required this.onTap,
  });

  final FocusArea area;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: area.xFraction * 310,
      top: area.yFraction * 560,
      child: AnimatedScale(
        scale: selected ? 1.04 : 1,
        duration: AppDurations.selection,
        curve: AppCurves.standard,
        child: Material(
          color: selected
              ? context.appColors.accent
              : context.appColors.surface,
          borderRadius: BorderRadius.circular(14),
          elevation: 4,
          shadowColor: context.appColors.textPrimary.withValues(alpha: 0.25),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: selected
                          ? context.appColors.accentPressed
                          : context.appColors.divider,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: AnimatedScale(
                      scale: selected ? 1 : 0,
                      duration: AppDurations.selection,
                      curve: AppCurves.overshoot,
                      child: Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: context.appColors.onAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    area.label,
                    style: AppTypography.title(
                      14,
                      selected
                          ? context.appColors.onAccent
                          : context.appColors.textPrimary,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
