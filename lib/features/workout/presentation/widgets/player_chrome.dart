import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/step_labels.dart';

/// Duration that collapses to zero when the OS asks for reduced motion.
Duration motion(BuildContext context, int ms) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: ms);

/// Small circular icon button (close, chevron, music).
class PlayerRoundButton extends StatelessWidget {
  const PlayerRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 40,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: c.surfaceMuted,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: AnimatedSwitcher(
                duration: motion(context, 200),
                child: Icon(
                  icon,
                  key: ValueKey(icon),
                  size: size * 0.55,
                  color: c.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One dash per step; filled up to and including [filled] - 1.
class SegmentedProgressBar extends StatelessWidget {
  const SegmentedProgressBar({
    super.key,
    required this.total,
    required this.filled,
  });
  final int total;
  final int filled;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      label: 'Step ${filled.clamp(0, total)} of $total',
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Expanded(
              child: AnimatedContainer(
                duration: motion(context, 220),
                curve: Curves.easeOut,
                height: 4,
                decoration: BoxDecoration(
                  color: i < filled ? c.accent : c.surfaceMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

TextStyle timerStyle(Color color, double size) => AppTypography.title(
  size,
  color,
  weight: FontWeight.w800,
  height: 1,
).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

/// The only widget that listens to the per-second countdown for the digits.
class CountdownText extends StatelessWidget {
  const CountdownText({super.key, required this.listenable, this.size = 64});
  final ValueListenable<int> listenable;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.textPrimary;
    return ValueListenableBuilder<int>(
      valueListenable: listenable,
      builder: (_, value, _) =>
          Text(formatTimer(value), style: timerStyle(color, size)),
    );
  }
}

/// Pill button on light surfaces. [primary] uses the brand fill.
class PlayerPill extends StatelessWidget {
  const PlayerPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.icon,
    this.height = 54,
  });
  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final fg = primary ? c.onAccent : c.textPrimary;
    return Material(
      color: primary ? c.accent : c.surfaceMuted,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Container(
          height: height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: fg),
                  const SizedBox(width: 8),
                ],
                Text(label, style: AppTypography.title(16, fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "+10s" pill that pops when tapped.
class ExtendPill extends StatefulWidget {
  const ExtendPill({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<ExtendPill> createState() => _ExtendPillState();
}

class _ExtendPillState extends State<ExtendPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _tap() {
    widget.onPressed();
    if (!MediaQuery.disableAnimationsOf(context)) _pop.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 60),
    ]).chain(CurveTween(curve: Curves.easeOut)).animate(_pop);
    return ScaleTransition(
      scale: scale,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: _tap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('+10s', style: AppTypography.title(13, c.accentText)),
          ),
        ),
      ),
    );
  }
}

/// Grey capsule with a brand fill showing progress of the current step and
/// three slots: previous, centre (pause/play or Done), next.
class StepCapsule extends StatelessWidget {
  const StepCapsule({
    super.key,
    this.countdown,
    this.total = 0,
    required this.center,
    required this.onPrevious,
    required this.onNext,
    this.showSkips = true,
  });

  /// False for a one-exercise try-out: only the centre control shows.
  final bool showSkips;

  /// Countdown of the step (null for rep sets: nothing to fill).
  final ValueListenable<int>? countdown;

  /// Seconds the countdown started from.
  final int total;
  final Widget center;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final fill = countdown;
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (fill != null)
            Positioned.fill(
              child: ValueListenableBuilder<int>(
                valueListenable: fill,
                builder: (context, left, _) => TweenAnimationBuilder<double>(
                  tween: Tween(
                    end: total <= 0 ? 0 : ((total - left) / total).clamp(0, 1),
                  ),
                  duration: motion(context, 1000),
                  curve: Curves.linear,
                  builder: (_, v, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: v,
                      heightFactor: 1,
                      child: ColoredBox(color: c.accent),
                    ),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: showSkips
                    ? IconButton(
                        tooltip: 'Previous',
                        onPressed: onPrevious,
                        icon: Icon(
                          Icons.skip_previous_rounded,
                          color: onPrevious == null
                              ? c.textMuted
                              : c.textPrimary,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(child: Center(child: center)),
              Expanded(
                child: showSkips
                    ? IconButton(
                        tooltip: 'Next',
                        onPressed: onNext,
                        icon: Icon(
                          Icons.skip_next_rounded,
                          color: c.textPrimary,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
