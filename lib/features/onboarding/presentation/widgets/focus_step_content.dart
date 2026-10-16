import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/bunny_image.dart';
import '../../../../shared/widgets/media_placeholder.dart';
import '../../domain/onboarding_step.dart';
import '../providers/onboarding_controller.dart';
import 'choice_step_content.dart';
import 'onboarding_viewport.dart';

/// Width / height of the trimmed figure picture (`where-should-we-focus`).
const _figureAspect = 0.5498;

/// Body-silhouette multi-select, like the reference: a big figure with the
/// pills on its left and right edges, level with the body part each one
/// names. Choosing one lights that part of the body up.
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

    // The figure is sized to the room below the headline, so the whole
    // screen fits without scrolling.
    final room = OnboardingViewport.maybeOf(context) ?? 560.0;
    return LayoutBuilder(
      builder: (context, box) {
        final maxH = (room - AppSpacing.lg).clamp(200.0, 900.0);
        final figureH =
            (box.maxWidth - 2 * AppSpacing.md) / _figureAspect < maxH
            ? (box.maxWidth - 2 * AppSpacing.md) / _figureAspect
            : maxH;
        final figureW = figureH * _figureAspect;
        return SizedBox(
          height: room,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: (box.maxWidth - figureW) / 2,
                top: 0,
                width: figureW,
                height: figureH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(child: _glowing(selected, context)),
                  ],
                ),
              ),
              for (final area in step.areas)
                _FocusPill(
                  area: area,
                  height: figureH,
                  selected: selected.contains(area.id),
                  sideInset: AppSpacing.md,
                  onTap: () => binding != null
                      ? binding!.onToggle(area.id)
                      : controller.toggleOption(step.id, area.id, multi: true),
                ),
            ],
          ),
        );
      },
    );
  }
}

extension on FocusStepContent {
  /// The figure with the glow painted only onto the body itself (never onto
  /// the empty space around it): each spot is a radial tint applied with
  /// `srcATop`, so it lands only where the picture has pixels.
  Widget _glowing(Set<String> selected, BuildContext context) {
    final accent = context.appColors.accent;
    Widget figure = BunnyImage(
      'onboarding/your-plan/where-should-we-focus',
      fit: BoxFit.fill,
      fallback: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 80),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(120),
            bottom: Radius.circular(24),
          ),
          child: const MediaPlaceholder(
            brief: 'Full-length athletic woman, front view, neutral stance',
          ),
        ),
      ),
    );
    for (final area in step.areas) {
      for (final spot in area.glow) {
        figure = _GlowMask(
          spot: spot,
          color: accent,
          on: selected.contains(area.id),
          child: figure,
        );
      }
    }
    return figure;
  }
}

/// One glowing spot on the body, fading in and out with the selection.
class _GlowMask extends StatelessWidget {
  const _GlowMask({
    required this.spot,
    required this.color,
    required this.on,
    required this.child,
  });

  final GlowSpot spot;
  final Color color;
  final bool on;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: on ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 420),
      curve: AppCurves.standard,
      child: child,
      builder: (context, t, child) {
        if (t == 0) return child!;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) =>
              RadialGradient(
                center: Alignment.center,
                radius: 0.5,
                colors: [
                  color.withValues(alpha: 0.85 * t),
                  color.withValues(alpha: 0.45 * t),
                  color.withValues(alpha: 0),
                ],
                stops: const [0, 0.55, 1],
              ).createShader(
                Rect.fromCircle(
                  center: Offset(spot.x * rect.width, spot.y * rect.height),
                  radius: spot.radius * rect.width,
                ),
              ),
          child: child,
        );
      },
    );
  }
}

class _FocusPill extends StatelessWidget {
  const _FocusPill({
    required this.area,
    required this.height,
    required this.selected,
    required this.sideInset,
    required this.onTap,
  });

  final FocusArea area;
  final double height;
  final bool selected;
  final double sideInset;
  final VoidCallback onTap;

  static const _pillHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final onRight = area.xFraction >= 0.5;
    final pill = AnimatedScale(
      scale: selected ? 1.05 : 1,
      duration: AppDurations.selection,
      curve: AppCurves.standard,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.selection,
          curve: AppCurves.standard,
          height: _pillHeight,
          padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_pillHeight),
            color: selected ? null : c.surface,
            gradient: selected
                ? LinearGradient(
                    colors: [c.accent, Color.lerp(c.accent, c.softRose, 0.45)!],
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: (selected ? c.accent : c.textPrimary).withValues(
                  alpha: selected ? 0.35 : 0.10,
                ),
                blurRadius: selected ? 14 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? c.onAccent.withValues(alpha: 0.28)
                      : c.softRose,
                ),
                alignment: Alignment.center,
                child: selected
                    ? Icon(Icons.check_rounded, size: 17, color: c.onAccent)
                    : Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.accent,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                area.label,
                style: AppTypography.title(
                  15,
                  selected ? c.onAccent : c.textPrimary,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Positioned(
      left: onRight ? null : sideInset,
      right: onRight ? sideInset : null,
      top: area.yFraction * height - _pillHeight / 2,
      child: pill,
    );
  }
}
