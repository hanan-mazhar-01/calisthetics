import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../media/data/media_manifest.dart';
import '../../../media/presentation/media_slot.dart';

/// Hero image header that collapses into a plain top bar while the list
/// scrolls. Expanded: plan hero photo under a dark scrim with solid
/// translucent circular buttons. Collapsed: plain bar, themed icons.
class DayHeaderDelegate extends SliverPersistentHeaderDelegate {
  DayHeaderDelegate({
    required this.topInset,
    required this.musicOn,
    required this.onBack,
    required this.onToggleMusic,
    required this.animate,
    this.expandedBody = 240,
  });

  final double topInset;
  final bool musicOn;
  final VoidCallback onBack;
  final VoidCallback onToggleMusic;
  final bool animate;
  final double expandedBody;

  static const double bar = 56;

  @override
  double get maxExtent => topInset + expandedBody;
  @override
  double get minExtent => topInset + bar;

  @override
  bool shouldRebuild(DayHeaderDelegate old) =>
      old.topInset != topInset ||
      old.musicOn != musicOn ||
      old.animate != animate;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final c = context.appColors;
    final range = math.max(1.0, maxExtent - minExtent);
    final t = (shrinkOffset / range).clamp(0.0, 1.0); // 0 expanded, 1 collapsed
    final heroOpacity = (1 - t * 1.25).clamp(0.0, 1.0);
    final iconColor = Color.lerp(c.onCover, c.textPrimary, t)!;
    final circle = Color.lerp(
      c.cover.withValues(alpha: 0.55),
      c.cover.withValues(alpha: 0),
      t,
    )!;

    return Container(
      color: c.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            key: const ValueKey('day-hero'),
            opacity: heroOpacity,
            child: Transform.translate(
              // Parallax: the image drifts up at half the scroll speed.
              offset: Offset(0, animate ? shrinkOffset * 0.5 : 0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const MediaSlot(
                    slot: MediaSlotSpec('plan-hero', 'Plan hero photo'),
                    width: 900,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          c.cover.withValues(alpha: 0.45),
                          c.cover.withValues(alpha: 0.1),
                          c.cover.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: topInset,
            height: bar,
            child: Row(
              children: [
                DayCircleButton(
                  key: const ValueKey('day-back'),
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  fill: circle,
                  color: iconColor,
                  onPressed: onBack,
                ),
                const Spacer(),
                DayCircleButton(
                  key: const ValueKey('day-music'),
                  icon: musicOn
                      ? Icons.music_note_rounded
                      : Icons.music_off_rounded,
                  tooltip: musicOn ? 'Turn music off' : 'Turn music on',
                  fill: circle,
                  color: iconColor,
                  onPressed: onToggleMusic,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Solid (non-blurred) circular icon button.
class DayCircleButton extends StatelessWidget {
  const DayCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.fill,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color fill;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

/// Title + meta chips shown under the hero.
class DayTitleBlock extends StatelessWidget {
  const DayTitleBlock({super.key, required this.title, required this.chips});
  final String title;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.title(26, c.textPrimary)),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            children: chips,
          ),
        ],
      ),
    );
  }
}

/// Icon + label meta chip; tappable when [onTap] is given.
class DayMetaChip extends StatelessWidget {
  const DayMetaChip({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: c.textPrimary),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.body(c.textPrimary, fontSize: 14)),
      ],
    );
    if (onTap == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: row,
      ),
    );
  }
}
