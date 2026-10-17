import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/app_background.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/models/calisthenics_skill.dart';
import '../../../exercises/domain/exercise.dart';
import '../../../exercises/domain/exercise_lookup.dart';
import '../providers/discover_providers.dart';
import '../widgets/discover_cards.dart';
import '../widgets/exercise_tile.dart';

/// A skill ladder: its ordered rungs with level, current rung and lock state.
class LadderScreen extends ConsumerWidget {
  const LadderScreen({super.key, required this.skillId, required this.title});

  final String skillId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rungs = ladderFor(skillId);
    final current = ref.watch(currentRungProvider(skillId));
    final policy = ref.watch(exerciseAccessPolicyProvider);
    return _ListScaffold(
      title: title,
      subtitle:
          'Easiest to hardest. Move up when the current rung feels solid.',
      children: [
        for (var i = 0; i < rungs.length; i++)
          ExerciseTile(
            exercise: rungs[i],
            rung: i + 1,
            current: rungs[i].number == current.number,
            locked: !policy.canPlayVideo(rungs[i]),
          ),
      ],
    );
  }
}

/// All eight skill ladders with the user's current rung.
class LaddersScreen extends ConsumerWidget {
  const LaddersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ListScaffold(
      title: 'Skill ladders',
      subtitle: 'Eight skills, each a ladder from the first rung to the full movement.',
      children: [
        for (final skill in calisthenicsSkills)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SizedBox(
              height: 190,
              child: Consumer(
                builder: (context, ref, _) {
                  final rung = ref.watch(currentRungProvider(skill.id));
                  final ladder = ladderFor(skill.id);
                  final index =
                      ladder.indexWhere((r) => r.number == rung.number) + 1;
                  return GradientProgramCard(
                    width: double.infinity,
                    imageKey: 'thumbnails/ladder_${skill.id}',
                    colors: skillGradients[skill.id]!,
                    kicker: '${ladder.length} RUNGS',
                    title: skill.label,
                    blurb: 'Your rung: ${rung.name}',
                    buttonLabel: index > 1 ? 'CONTINUE' : 'START',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LadderScreen(
                          skillId: skill.id,
                          title: '${skill.label} ladder',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// A flat section (Foundation area, Warm-up & Mobility).
class SectionScreen extends StatelessWidget {
  const SectionScreen({
    super.key,
    required this.title,
    required this.exercises,
  });

  final String title;
  final List<Exercise> exercises;

  @override
  Widget build(BuildContext context) => _ListScaffold(
    title: title,
    children: [for (final e in exercises) ExerciseTile(exercise: e)],
  );
}

class _ListScaffold extends StatelessWidget {
  const _ListScaffold({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GradientScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Row(
              children: [
                GlassButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.title(26, c.textPrimary)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: AppTypography.body(c.textSecondary)),
            ],
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
