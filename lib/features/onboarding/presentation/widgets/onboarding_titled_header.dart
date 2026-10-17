import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/onboarding_step.dart';
import 'typewriter_text.dart';

/// Shared headline+subtitle block rendered under the chrome header on every
/// choice/curve step (the middle headline segment renders in brand rose).
///
/// The headline types itself out (with haptic ticks) and the subtitle fades
/// in once it is done. Pass [animate] false for static screens (settings).
class OnboardingTitledHeader extends StatefulWidget {
  const OnboardingTitledHeader({
    super.key,
    required this.headline,
    this.subtitle,
    this.onTyped,
    this.animate = true,
  });

  final Headline headline;
  final String? subtitle;

  /// Called once the headline has finished typing.
  final VoidCallback? onTyped;
  final bool animate;

  @override
  State<OnboardingTitledHeader> createState() => _OnboardingTitledHeaderState();
}

class _OnboardingTitledHeaderState extends State<OnboardingTitledHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _subtitle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void dispose() {
    _subtitle.dispose();
    super.dispose();
  }

  void _typed() {
    if (!mounted) return;
    _subtitle.forward();
    widget.onTyped?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final style = AppTypography.display(
      fontSize: 32,
      color: c.textPrimary,
      stretchPercent: 85,
      letterSpacingEm: -0.02,
    );
    final h = widget.headline;
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
          if (widget.animate)
            TypewriterText(
              style: style,
              onDone: _typed,
              segments: [
                TypeSegment(h.lead),
                TypeSegment(h.accent, AppTypography.accentSerif(c.accentText)),
                TypeSegment(h.tail),
              ],
            )
          else
            RichText(
              text: TextSpan(
                style: style,
                children: [
                  TextSpan(text: h.lead),
                  TextSpan(
                    text: h.accent,
                    style: AppTypography.accentSerif(c.accentText),
                  ),
                  TextSpan(text: h.tail),
                ],
              ),
            ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: AppSpacing.md),
            widget.animate
                ? FadeTransition(
                    opacity: _subtitle,
                    child: Text(
                      widget.subtitle!,
                      style: AppTypography.body(c.textSecondary),
                    ),
                  )
                : Text(
                    widget.subtitle!,
                    style: AppTypography.body(c.textSecondary),
                  ),
          ],
        ],
      ),
    );
  }
}
