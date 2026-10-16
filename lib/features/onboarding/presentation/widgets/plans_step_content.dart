import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/bunny_image.dart';
import '../../../exercises/domain/exercise_lookup.dart';
import '../../../exercises/presentation/widgets/exercise_picture.dart';
import '../../../plans/domain/plan_recommender.dart';
import '../../../plans/domain/plan_template.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../domain/onboarding_plan_summary.dart';
import '../providers/onboarding_controller.dart';

/// Plan selection: the recommender's "best for you" plan as a photo hero card,
/// then "or explore" with every other plan as a grid of round photos. Plans
/// that need a bar she doesn't have are tagged but selectable; plans that load
/// a protected area are dimmed, marked, and can't be picked.
class PlansStepContent extends ConsumerWidget {
  const PlansStepContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selections = ref.watch(
      onboardingControllerProvider.select((s) => s.selections),
    );
    final plank = ref.watch(
      onboardingControllerProvider.select((s) => s.plankSeconds),
    );
    final controller = ref.read(onboardingControllerProvider.notifier);
    final today = ref.read(clockProvider)();

    final recs = recommendationsFor(selections, plankSeconds: plank);
    final hero = heroRecommendation(recs);
    final others = [
      for (final r in recs)
        if (r.template.id != hero.template.id) r,
    ];

    final chosenId = selections[planChoiceKey]?.firstOrNull;
    final chosenValid = recs.any(
      (r) => r.template.id == chosenId && r.conflicts.isEmpty,
    );
    final effectiveId = chosenValid ? chosenId! : hero.template.id;
    if (effectiveId != chosenId) {
      // Persist the default (or replace a pick that no longer fits).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.choosePlan(effectiveId);
      });
    }

    final summary = OnboardingPlanSummary.from(
      {
        ...selectionsForRecommendation(selections),
        planChoiceKey: {hero.template.id},
      },
      plankSeconds: plank,
      today: today,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.screenBottomCta,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroCard(
            rec: hero,
            summary: summary,
            selected: effectiveId == hero.template.id,
            onTap: hero.conflicts.isEmpty
                ? () => controller.choosePlan(hero.template.id)
                : null,
          ),
          const _ExploreDivider(),
          LayoutBuilder(
            builder: (context, box) {
              const gap = 12.0;
              final itemWidth = (box.maxWidth - gap * 2) / 3;
              return Wrap(
                spacing: gap,
                runSpacing: AppSpacing.xl,
                children: [
                  for (final r in others)
                    SizedBox(
                      width: itemWidth,
                      child: _PlanBubble(
                        rec: r,
                        selected: effectiveId == r.template.id,
                        onTap: r.conflicts.isEmpty
                            ? () => controller.choosePlan(r.template.id)
                            : null,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

String _focusLabel(PlanFocus f) => switch (f) {
  PlanFocus.fullBody => 'Full body',
  PlanFocus.core => 'Core',
  PlanFocus.legsGlutes => 'Legs & glutes',
  PlanFocus.conditioning => 'Conditioning',
  PlanFocus.mobility => 'Mobility',
  PlanFocus.skill => 'Skill',
};

String _levelLabel(PlanTemplate t) {
  String name(PlanLevel l) => switch (l) {
    PlanLevel.beginner => 'Beginner',
    PlanLevel.intermediate => 'Intermediate',
    PlanLevel.advanced => 'Advanced',
  };
  final first = t.stages.first.level;
  final last = t.stages.last.level;
  return first == last ? name(first) : '${name(first)} to ${name(last)}';
}

/// "No equipment" -> "None"; several items -> "Wall +2".
String _shortEquipment(PlanTemplate t) {
  final label = planEquipmentLabel(t);
  if (label == 'No equipment') return 'None';
  final parts = label.split(', ');
  return parts.length == 1
      ? parts.first
      : '${parts.first} +${parts.length - 1}';
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.rec,
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final PlanRecommendation rec;
  final OnboardingPlanSummary? summary;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final t = rec.template;
    final gearTag = missingGearTag(rec.missingGear);
    final cadence = summary == null
        ? null
        : '${summary!.sessionsPerWeek}× a week · ${summary!.minutesLabel}';
    final tags = [_focusLabel(t.focus), _levelLabel(t), ?gearTag];

    return Semantics(
      button: true,
      selected: selected,
      label: 'Best for you: ${t.name}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          // The ring is part of the card (no gap), so it hugs the photo.
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: selected ? c.accent : Colors.transparent,
              width: 3.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28.5),
            child: Stack(
              children: [
                Positioned.fill(child: _HeroBackground(template: t)),
                // Darkens the photo so the white text stays readable.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          c.cover.withValues(alpha: 0.28),
                          c.cover.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 18,
                                  color: c.accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'BEST FOR YOU',
                                  style: AppTypography.kicker(
                                    c.accentText,
                                    fontSize: 13,
                                    letterSpacingEm: 0.05,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (selected)
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: c.accent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 20,
                                color: c.onAccent,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 56),
                      Text(
                        t.name,
                        style: AppTypography.display(
                          fontSize: 36,
                          color: Colors.white,
                          stretchPercent: 80,
                          letterSpacingEm: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          Colors.white.withValues(alpha: 0.92),
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [for (final tag in tags) _OutlineTag(tag)],
                      ),
                      const SizedBox(height: 16),
                      _InfoPanel(
                        duration: '4 weeks',
                        cadence: cadence,
                        equipment: _shortEquipment(t),
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

/// The plan's picture: the thumbnail of its lead exercise; until it loads,
/// a plain blush gradient, so no placeholder label sits behind the text.
class _HeroBackground extends StatelessWidget {
  const _HeroBackground({required this.template});

  final PlanTemplate template;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.softRose, c.surfaceMuted],
        ),
      ),
    );
    return BunnyImage(
      exerciseThumbnailKey(exerciseByNumber(template.coverExerciseNumber)),
      fit: BoxFit.cover,
      fallback: fallback,
    );
  }
}

class _OutlineTag extends StatelessWidget {
  const _OutlineTag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: Text(
        text,
        style: AppTypography.body(
          Colors.white,
          fontSize: 14,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// White panel at the bottom of the hero: DURATION | EQUIPMENT.
class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.duration,
    required this.cadence,
    required this.equipment,
  });

  final String duration;
  final String? cadence;
  final String equipment;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _InfoCell(
                icon: Icons.schedule_rounded,
                label: 'DURATION',
                value: duration,
                caption: cadence,
              ),
            ),
            VerticalDivider(color: c.divider, width: 24, thickness: 1),
            Expanded(
              child: _InfoCell(
                icon: Icons.fitness_center_rounded,
                label: 'EQUIPMENT',
                value: equipment,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.surfaceSelected,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: c.accentText),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.kicker(
                  c.textSecondary,
                  fontSize: 12,
                  letterSpacingEm: 0.06,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title(
                  19,
                  c.accentText,
                  weight: FontWeight.w700,
                ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(c.textMuted, fontSize: 11.5),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExploreDivider extends StatelessWidget {
  const _ExploreDivider();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Row(
        children: [
          Expanded(child: Divider(color: c.divider, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'OR EXPLORE',
              style: AppTypography.kicker(
                c.textSecondary,
                fontSize: 14,
                letterSpacingEm: 0.2,
              ),
            ),
          ),
          Expanded(child: Divider(color: c.divider, height: 1)),
        ],
      ),
    );
  }
}

/// One plan in the explore grid: round photo with a status dot, name, and a
/// pink kicker. Protected-area conflicts are dimmed and say why.
class _PlanBubble extends StatelessWidget {
  const _PlanBubble({
    required this.rec,
    required this.selected,
    required this.onTap,
  });

  final PlanRecommendation rec;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final t = rec.template;
    final gearTag = missingGearTag(rec.missingGear);
    final blocked = rec.conflicts.isNotEmpty;
    final kicker = blocked ? protectedConflictLabel(rec.conflicts) : t.tagline;
    return Semantics(
      button: true,
      selected: selected,
      enabled: !blocked,
      label: '${t.name}. $kicker${gearTag == null ? '' : '. $gearTag'}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: blocked ? 0.55 : 1,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? c.accent : Colors.transparent,
                              width: 3.5,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: c.accent.withValues(alpha: 0.3),
                                      blurRadius: 16,
                                    ),
                                  ]
                                : null,
                          ),
                          child: ClipOval(
                            child: ExercisePicture(
                              exercise: exerciseByNumber(t.coverExerciseNumber),
                              compact: true,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 2,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected ? c.accent : c.surface,
                            boxShadow: [
                              BoxShadow(
                                color: c.textPrimary.withValues(alpha: 0.12),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: selected
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 17,
                                  color: c.onAccent,
                                )
                              : Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: c.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title(
                  14.5,
                  c.textPrimary,
                  weight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                kicker.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.kicker(
                  blocked ? c.warning : c.accentText,
                  fontSize: 10.5,
                  letterSpacingEm: 0.04,
                ),
              ),
              if (gearTag != null) ...[
                const SizedBox(height: 2),
                Text(
                  gearTag,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(c.textMuted, fontSize: 10.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
