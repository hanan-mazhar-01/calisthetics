import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../exercises/domain/exercise_lookup.dart';
import '../../../plans/data/plan_templates.dart';
import '../../../user/domain/completed_session.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../domain/progression_feedback.dart';
import '../../domain/step_labels.dart';
import '../../domain/workout_request.dart';
import '../providers/workout_controller.dart';
import '../../../exercises/presentation/widgets/exercise_thumb.dart';

/// Shown once the session is saved to local history (no network needed).
class WorkoutCompleteView extends ConsumerWidget {
  const WorkoutCompleteView({
    super.key,
    required this.request,
    required this.onClose,
  });

  final WorkoutRequest request;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final saved = ref.read(workoutControllerProvider(request).notifier).saved;
    final streak = ref.watch(userStatsProvider).currentStreak;
    final exercises = saved?.exerciseNumbers ?? const <int>[];
    final minutes = ((saved?.durationSeconds ?? 0) / 60).round();
    final next = _nextStep(saved);

    return DecoratedBox(
      // Follows the app theme: light screen in light mode, dark in dark.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.softRose.withValues(alpha: 0.55), c.background],
          stops: const [0, 0.42],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WORKOUT COMPLETE',
                style: AppTypography.kicker(c.accentText),
              ),
              const SizedBox(height: 8),
              Text(
                request.session.name,
                style: AppTypography.title(30, c.textPrimary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _Stat(
                    icon: Icons.schedule_rounded,
                    label: 'Time',
                    value: saved == null
                        ? '-'
                        : (minutes < 1
                              ? formatClock(saved.durationSeconds)
                              : '$minutes min'),
                  ),
                  const SizedBox(width: 10),
                  _Stat(
                    icon: Icons.fitness_center_rounded,
                    label: 'Exercises',
                    value: '${exercises.length}',
                  ),
                  const SizedBox(width: 10),
                  _Stat(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Day streak',
                    value: '$streak',
                  ),
                ],
              ),
              if (next != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.surfaceSelected,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, color: c.accentText),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          next,
                          style: AppTypography.title(16, c.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'How it felt',
                style: AppTypography.title(17, c.textPrimary),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: exercises.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final n = exercises[i];
                    final effort = saved?.efforts[n];
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          ExerciseThumb(
                            number: n,
                            size: 48,
                            radiusFactor: 0.25,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              exerciseByNumber(n).name,
                              style: AppTypography.title(15, c.textPrimary),
                            ),
                          ),
                          if (effort != null) _EffortChip(effort: effort),
                          const SizedBox(width: 4),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: c.onAccent,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: onClose,
                  child: Text(
                    'Done',
                    style: AppTypography.title(16, c.onAccent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Only skill sessions can earn this, and only from the Easy ratings.
  String? _nextStep(CompletedSession? saved) {
    if (saved == null) return null;
    final skillId = [
      for (final t in planTemplates)
        if (t.id == request.templateId) t.skillId,
    ].firstOrNull;
    if (skillId == null) return null;
    // Rungs and session items are compared by video: a plan may use the
    // foundation twin of a ladder rung (same movement, different number).
    int video(int n) => exerciseByNumber(n).videoNumber;
    return ProgressionFeedback.readyForNextStep(
      ladder: [for (final e in ladderFor(skillId)) e.videoNumber],
      sessionExercises: [for (final n in saved.exerciseNumbers) video(n)],
      efforts: {for (final e in saved.efforts.entries) video(e.key): e.value},
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: c.accentText),
            const SizedBox(height: 8),
            Text(value, style: AppTypography.title(22, c.textPrimary)),
            Text(
              label,
              style: AppTypography.body(c.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// How she rated the exercise: Easy / Just right / Hard.
class _EffortChip extends StatelessWidget {
  const _EffortChip({required this.effort});
  final Effort effort;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final (label, bg, fg) = switch (effort) {
      Effort.easy => ('Easy', c.surfaceMuted, c.textSecondary),
      Effort.justRight => ('Just right', c.surfaceSelected, c.accentText),
      Effort.hard => ('Hard', c.accent, c.onAccent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.body(fg, fontSize: 12, weight: FontWeight.w500),
      ),
    );
  }
}
