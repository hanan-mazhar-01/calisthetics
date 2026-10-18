import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/bunny_image.dart';
import '../../../exercises/domain/exercise.dart';
import '../../../exercises/presentation/widgets/exercise_thumb.dart';

/// "Title ........ See All >" row that heads every Discover section.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.title(
                22,
                c.textPrimary,
                weight: FontWeight.w800,
              ),
            ),
          ),
          if (onSeeAll != null)
            Semantics(
              button: true,
              label: 'See all $title',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onSeeAll,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'See All',
                        style: AppTypography.body(
                          c.textMuted,
                          fontSize: 14.5,
                          weight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: c.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontal strip with the page's 20px gutter on both ends.
class HorizontalStrip extends StatelessWidget {
  const HorizontalStrip({
    super.key,
    required this.height,
    required this.children,
    this.gap = 14,
  });

  final double height;
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: children.length,
        separatorBuilder: (_, _) => SizedBox(width: gap),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

/// Exercise card: image slot with level/equipment chips and a play badge,
/// title underneath (the Top Picks / Foundation style).
class ExercisePhotoCard extends StatelessWidget {
  const ExercisePhotoCard({
    super.key,
    required this.exercise,
    required this.onTap,
    this.width = 250,
  });

  final Exercise exercise;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      label: '${exercise.name}, ${exercise.level.label}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.55,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ExerciseThumb(
                        number: exercise.number,
                        size: 400,
                        radiusFactor: 0,
                      ),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Wrap(
                          spacing: 6,
                          children: [_OverlayChip(exercise.level.label)],
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.cover.withValues(alpha: 0.55),
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                exercise.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title(
                  16,
                  c.textPrimary,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayChip extends StatelessWidget {
  const _OverlayChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: context.appColors.cover.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: AppTypography.body(
          Colors.white,
          fontSize: 12,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Coloured gradient card used for skill ladders ("N RUNGS", title, blurb, button).
/// Displays background photography from [imageKey] when provided, with an
/// overlay ensuring typography and the action button remain crisp.
class GradientProgramCard extends StatelessWidget {
  const GradientProgramCard({
    super.key,
    required this.colors,
    required this.kicker,
    required this.title,
    required this.blurb,
    required this.buttonLabel,
    required this.onTap,
    this.width = 290,
    this.imageKey,
  });

  final List<Color> colors;
  final String kicker;
  final String title;
  final String blurb;
  final String buttonLabel;
  final VoidCallback onTap;
  final double width;
  final String? imageKey;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      label: '$title, $kicker. $buttonLabel',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Container(
            width: width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageKey != null) ...[
                  BunnyImage(imageKey!, fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.first.withValues(alpha: 0.30),
                          Colors.black.withValues(alpha: 0.78),
                        ],
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kicker,
                        style: AppTypography.kicker(
                          Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title(
                          26,
                          Colors.white,
                          weight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          blurb,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            Colors.white.withValues(alpha: 0.92),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          buttonLabel,
                          style: AppTypography.title(
                            15,
                            c.textPrimary,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
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

/// Round "Target Area" bubble with photo thumbnail and title.
class AreaBubble extends StatelessWidget {
  const AreaBubble({
    super.key,
    required this.label,
    required this.colors,
    required this.onTap,
    this.imageKey,
  });

  final String label;
  final List<Color> colors;
  final VoidCallback onTap;
  final String? imageKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipOval(
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageKey != null) ...[
                  BunnyImage(imageKey!, fit: BoxFit.cover),
                  Container(color: Colors.black.withValues(alpha: 0.45)),
                ],
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      label.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: AppTypography.title(
                        13,
                        Colors.white,
                        weight: FontWeight.w900,
                        height: 1.1,
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

/// White rounded chip ("Time" / "Equipment" style).
class SoftChip extends StatelessWidget {
  const SoftChip({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool selected;

  /// Smaller, fully rounded pill (search filters, equipment).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final fg = selected ? c.onAccent : c.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? c.accent : c.surface,
            borderRadius: BorderRadius.circular(compact ? 999 : 14),
            boxShadow: selected
                ? null
                : [
                    BoxShadow(
                      color: c.textPrimary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTypography.body(
                  fg,
                  fontSize: 15,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ladder palettes: one soft gradient per skill, all in the brand's warm family
/// plus two cool accents for variety.
const skillGradients = <String, List<Color>>{
  'push-up': [Color(0xFFD85F70), Color(0xFFE88A97)],
  'pull-up': [Color(0xFF8C4F7A), Color(0xFFB070A0)],
  'chin-up': [Color(0xFFE27A4E), Color(0xFFF0A07A)],
  'dips': [Color(0xFFB83B5E), Color(0xFFD8688A)],
  'handstand': [Color(0xFF5F7FA8), Color(0xFF8DA7C8)],
  'l-sit': [Color(0xFF6E8F7E), Color(0xFF9BB5A6)],
  'pistol-squat': [Color(0xFF9A6B8F), Color(0xFFC197B8)],
  'toes-to-bar': [Color(0xFFD99A65), Color(0xFFF0C48A)],
};

const areaGradients = <String, List<Color>>{
  'foundation-upper': [Color(0xFF8C4F7A), Color(0xFFB070A0)],
  'foundation-core': [Color(0xFFD85F70), Color(0xFFE88A97)],
  'foundation-legs': [Color(0xFF5F7FA8), Color(0xFF8DA7C8)],
  'foundation-conditioning': [Color(0xFFE27A4E), Color(0xFFF0A07A)],
  'warmup-mobility': [Color(0xFF6E8F7E), Color(0xFF9BB5A6)],
};
