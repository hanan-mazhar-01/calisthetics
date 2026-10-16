import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/app_background.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../discover/domain/discover_logic.dart';
import '../../../discover/presentation/providers/discover_providers.dart';
import '../../../discover/presentation/widgets/premium_sheet.dart';
import '../../../media/presentation/media_providers.dart';
import '../../../workout/domain/workout_request.dart';
import '../../domain/exercise.dart';
import '../../domain/exercise_lookup.dart';
import '../widgets/exercise_chips.dart';
import '../widgets/exercise_video_slot.dart';

/// Full page for one catalog exercise. Content comes straight from the
/// catalog; nothing is added here.
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.number});

  /// Catalog exercise number (1–115).
  final int number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final e = exerciseByNumber(number);
    final media = ref.watch(mediaRepositoryProvider);
    final policy = ref.watch(exerciseAccessPolicyProvider);
    final locked = !policy.canPlayVideo(e);
    final nb = neighboursOf(e);

    return GradientScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            Row(
              children: [
                GlassButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                ),
                const Spacer(),
                FavoriteHeart(number: e.number, size: 26),
              ],
            ),
            const SizedBox(height: 12),
            ExerciseVideoSlot(
              key: ValueKey(e.number),
              exerciseName: e.name,
              url: media.exerciseVideo(e),
              locked: locked,
              onPlay: () => context.push(
                '/workout',
                extra: WorkoutRequest.demo(e.number, e.name),
              ),
              onLockedTap: () => showPremiumSheet(
                context,
                message: 'Videos for this ladder rung are part of Premium.',
              ),
            ),
            const SizedBox(height: 16),
            Text(e.name, style: AppTypography.title(26, c.textPrimary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InfoChip(
                  label: e.level.label,
                  icon: Icons.signal_cellular_alt_rounded,
                ),
                InfoChip(
                  label: e.equipment,
                  icon: Icons.fitness_center_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(e.purpose, style: AppTypography.body(c.textSecondary)),
            if (e.startingPosition != null)
              _Block(title: 'Starting position', text: e.startingPosition!),
            if (e.steps.isNotEmpty) _Steps(steps: e.steps),
            if (e.breathing != null)
              _Block(title: 'Breathing', text: e.breathing!),
            if (e.cues != null) _Block(title: 'Key cues', text: e.cues!),
            if (e.mistakes != null)
              _Block(title: 'Common mistakes', text: e.mistakes!),
            if (e.safety != null) _Block(title: 'Safety', text: e.safety!),
            if (e.easier != null || nb.easier != null)
              _Neighbour(
                title: 'Easier',
                text: e.easier,
                target: nb.easier,
                icon: Icons.south_west_rounded,
              ),
            if (e.harder != null || nb.harder != null)
              _Neighbour(
                title: 'Harder',
                text: e.harder,
                target: nb.harder,
                icon: Icons.north_east_rounded,
              ),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: GlassCard(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.title(16, c.textPrimary)),
              const SizedBox(height: 6),
              Text(text, style: AppTypography.body(c.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.steps});
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: GlassCard(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How to', style: AppTypography.title(16, c.textPrimary)),
              const SizedBox(height: 10),
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.softRose,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: AppTypography.title(12, c.accentText),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          steps[i],
                          style: AppTypography.body(c.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Neighbour extends StatelessWidget {
  const _Neighbour({
    required this.title,
    required this.text,
    required this.target,
    required this.icon,
  });

  final String title;
  final String? text;
  final Exercise? target;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: GlassCard(
        onTap: target == null
            ? null
            : () => context.push('/exercise/${target!.number}'),
        child: Row(
          children: [
            Icon(icon, color: c.accentText),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target == null ? title : '$title: ${target!.name}',
                    style: AppTypography.title(16, c.textPrimary),
                  ),
                  if (text != null) ...[
                    const SizedBox(height: 4),
                    Text(text!, style: AppTypography.body(c.textSecondary)),
                  ],
                ],
              ),
            ),
            if (target != null)
              Icon(Icons.chevron_right_rounded, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
