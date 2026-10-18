import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/bunny_image.dart';
import '../../../exercises/domain/exercise_lookup.dart';
import '../../../exercises/presentation/widgets/exercise_picture.dart'
    show exerciseThumbnailKey;
import '../../../plans/data/plan_templates.dart';
import '../../../plans/domain/plan_template.dart';
import '../../domain/plan_showcase.dart';

/// Colours of a plan's card: one pair per plan, so each plan is easy to tell
/// apart in the list. White text reads on all of them.
const _gradients = <List<Color>>[
  [Color(0xFFFF8A5B), Color(0xFFE5522F)],
  [Color(0xFFFF5C93), Color(0xFFD9185A)],
  [Color(0xFF34BFA6), Color(0xFF117F73)],
  [Color(0xFF3FA9E0), Color(0xFF1B6FB0)],
  [Color(0xFF86B83A), Color(0xFF4C8216)],
  [Color(0xFF9B6BFF), Color(0xFF5B34CC)],
  [Color(0xFFE9A02E), Color(0xFFBB6A0C)],
  [Color(0xFFD85F70), Color(0xFF9F3447)],
];

List<Color> planColors(PlanTemplate t) {
  final i = planTemplates.indexWhere((p) => p.id == t.id);
  return _gradients[(i < 0 ? 0 : i) % _gradients.length];
}

/// How far a plan the user already follows has got (shown on "My Plan").
class PlanProgressInfo {
  const PlanProgressInfo({
    required this.doneDays,
    required this.totalDays,
    required this.phaseDone,
  });
  final int doneDays;
  final int totalDays;
  final List<bool> phaseDone;
}

/// A plan as a colourful card: its name, a photo, and (full size) how long it
/// is, what it needs and three tags. With [progress] it is the shorter "My
/// Plan" card showing days done instead.
class PlanShowcaseCard extends StatelessWidget {
  const PlanShowcaseCard({
    super.key,
    required this.template,
    this.progress,
    this.isCurrent = false,
    this.onTap,
  });

  final PlanTemplate template;
  final PlanProgressInfo? progress;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = planColors(template);
    final compact = progress != null;
    final height = compact ? 150.0 : 262.0;
    return Semantics(
      button: onTap != null,
      label:
          '${template.name}. ${planLengthLabel(template)}.'
          '${isCurrent ? ' Current plan.' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            border: isCurrent
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 2,
                  )
                : null,
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final photoW = box.maxWidth * 0.55;
              return Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: photoW,
                    child: _Photo(template: template),
                  ),
                  Positioned(
                    left: 18,
                    top: 18,
                    width: box.maxWidth * 0.55,
                    child: Text(
                      template.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title(
                        22,
                        Colors.white,
                        weight: FontWeight.w700,
                        height: 1.12,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 5, 14, 6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Current plan',
                          style: AppTypography.title(
                            11.5,
                            colors.last,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (compact)
                    Positioned(
                      left: 18,
                      bottom: 16,
                      child: _ProgressRow(progress: progress!),
                    )
                  else
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: _InfoPanel(template: template, tint: colors.last),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The plan's cover photo, fading out towards the card's left so it melts
/// into the card colour (the glass panel sits over its lower part).
class _Photo extends StatelessWidget {
  const _Photo({required this.template});

  final PlanTemplate template;

  @override
  Widget build(BuildContext context) {
    final exercise = exerciseByNumber(template.coverExerciseNumber);
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0x00000000), Color(0xFF000000)],
        stops: [0, 0.5],
      ).createShader(rect),
      child: BunnyImage(
        exerciseThumbnailKey(exercise),
        fit: BoxFit.cover,
        cacheWidth: 520,
      ),
    );
  }
}

/// "3 Stage : 12 Weeks", what it needs, and three tags, on frosted glass.
class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.template, required this.tint});
  final PlanTemplate template;

  /// The card's deeper colour: the panel is a lighter, mostly solid shade of
  /// it, so the text stays readable over the photo behind.
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final tags = planTags(template);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          Colors.white.withValues(alpha: 0.14),
          tint.withValues(alpha: 0.9),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: _Fact(
                  icon: Icons.calendar_month_rounded,
                  caption: planLengthLabel(template),
                  bottom: template.stages.length > 1
                      ? _StageDots(count: template.stages.length)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: _Fact(
                  icon: Icons.fitness_center_rounded,
                  caption: 'Equipment',
                  value: planEquipmentLabel(template),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (i, t) in tags.indexed) ...[
                if (i > 0) const SizedBox(width: 6),
                // Wider pills for longer words, so none shrinks to a speck.
                Expanded(
                  flex: t.length + 6,
                  child: _Tag(label: t),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.caption,
    this.value,
    this.bottom,
  });

  final IconData icon;
  final String caption;
  final String? value;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final soft = Colors.white.withValues(alpha: 0.82);
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  caption,
                  style: AppTypography.body(soft, fontSize: 12),
                ),
              ),
              if (value != null)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value!,
                    style: AppTypography.title(
                      14.5,
                      Colors.white,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              if (bottom != null) ...[const SizedBox(height: 5), bottom!],
            ],
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(99),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: AppTypography.body(
            Colors.white,
            fontSize: 12,
            weight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// One dot per stage, joined by a thin line.
class _StageDots extends StatelessWidget {
  const _StageDots({required this.count, this.filled = const []});

  final int count;
  final List<bool> filled;

  @override
  Widget build(BuildContext context) {
    final line = Colors.white.withValues(alpha: 0.55);
    return SizedBox(
      width: 78,
      height: 9,
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) Expanded(child: Container(height: 1.5, color: line)),
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled.length && filled[i]
                    ? Colors.white
                    : Colors.transparent,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "1 / 21 Days" with a dot per phase, on the "My Plan" card.
class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.progress});
  final PlanProgressInfo progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${progress.doneDays} / ${progress.totalDays} Days',
          style: AppTypography.title(14, Colors.white, weight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        _StageDots(
          count: progress.phaseDone.length.clamp(1, 6),
          filled: progress.phaseDone,
        ),
      ],
    );
  }
}
