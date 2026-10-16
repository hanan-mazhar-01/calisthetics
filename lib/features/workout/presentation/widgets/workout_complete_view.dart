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
import 'workout_panels.dart';

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
      decoration: BoxDecoration(color: c.cover),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WORKOUT COMPLETE',
                style: AppTypography.kicker(c.coverAccent),
              ),
              const SizedBox(height: 8),
              Text(
                request.session.name,
                style: AppTypography.title(
                  30,
                  c.onCover,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _Stat(
                    label: 'Time',
                    value: saved == null
                        ? '-'
                        : (minutes < 1
                              ? formatClock(saved.durationSeconds)
                              : '$minutes min'),
                  ),
                  _Stat(label: 'Exercises', value: '${exercises.length}'),
                  _Stat(label: 'Day streak', value: '$streak'),
                ],
              ),
              if (next != null) ...[
                const SizedBox(height: 20),
                CoverGlass(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.trending_up, color: c.coverAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            next,
                            style: AppTypography.title(16, c.onCover),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    for (final n in exercises)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                exerciseByNumber(n).name,
                                style: AppTypography.body(c.onCover),
                              ),
                            ),
                            Text(
                              _effortLabel(saved?.efforts[n]),
                              style: AppTypography.body(
                                c.onCoverTertiary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: CoverButton(
                  label: 'Done',
                  primary: true,
                  onPressed: onClose,
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

  static String _effortLabel(Effort? e) => switch (e) {
    Effort.easy => 'Easy',
    Effort.justRight => 'Just right',
    Effort.hard => 'Hard',
    null => '',
  };
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.title(28, c.onCover, weight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.body(c.onCoverSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
