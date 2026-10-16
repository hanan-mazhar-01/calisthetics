import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../exercises/domain/exercise.dart';
import '../../../exercises/presentation/widgets/exercise_chips.dart';
import '../../../exercises/presentation/widgets/exercise_picture.dart';

/// List card for one exercise: a full-height photo on the left, then a small
/// kind label with a "Video" pill, the bold name, and "level • gear".
/// Used by search results, section lists and ladders.
class ExerciseTile extends StatelessWidget {
  const ExerciseTile({
    super.key,
    required this.exercise,
    this.rung,
    this.locked = false,
    this.current = false,
  });

  final Exercise exercise;

  /// 1-based position on a skill ladder; shown instead of the kind label.
  final int? rung;
  final bool locked;

  /// The user's current rung on this ladder.
  final bool current;

  static const _imageWidth = 116.0;
  static const _minHeight = 96.0;

  /// "Pull-up bar; band optional" -> "Pull-up bar".
  static String shortEquipment(String equipment) {
    final first = equipment.split(RegExp(r'[;—]')).first.trim();
    return first.isEmpty ? equipment : first;
  }

  static String kindOf(Exercise e) {
    final id = e.sectionId;
    if (id.startsWith('skill-')) return 'Skill';
    if (id.startsWith('foundation-')) return 'Foundation';
    if (id == 'warmup-mobility') return 'Warm-up';
    return 'Variation';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        label: '${exercise.name}, ${exercise.level.label}',
        child: Material(
          color: c.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: current
                ? BorderSide(color: c.accent, width: 1.6)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () => context.push('/exercise/${exercise.number}'),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minHeight),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: _imageWidth,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ExercisePicture(exercise: exercise),
                          if (locked)
                            Positioned(
                              left: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: c.cover.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          rung != null
                                              ? 'Rung $rung'
                                              : kindOf(exercise),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.body(
                                            current
                                                ? c.accentText
                                                : c.textMuted,
                                            fontSize: 13,
                                            weight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      const _VideoPill(),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    exercise.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.title(
                                      17,
                                      c.textPrimary,
                                      weight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${exercise.level.label} • ${shortEquipment(exercise.equipment)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.body(
                                      c.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FavoriteHeart(number: exercise.number, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small outlined "Video" tag.
class _VideoPill extends StatelessWidget {
  const _VideoPill();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.accent, width: 1),
      ),
      child: Text(
        'Video',
        style: AppTypography.body(
          c.accentText,
          fontSize: 11.5,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}
