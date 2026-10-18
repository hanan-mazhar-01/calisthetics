import '../../exercises/domain/exercise.dart';
import '../../exercises/domain/exercise_lookup.dart';

/// THE one place that decides what a free user can open.
///
///  * Free: one plan, and the exercises in that plan play;
///  * every other Discover exercise video needs Premium;
///  * exercise pages stay visible to everyone (with a lock on the video);
///  * starting plans beyond the free one needs Premium.
class ExerciseAccessPolicy {
  const ExerciseAccessPolicy({
    required this.isPremium,
    this.planExerciseNumbers = const {},
  });

  final bool isPremium;

  /// Catalog numbers used by the user's active plan.
  final Set<int> planExerciseNumbers;

  bool canViewPage(Exercise e) => true;

  bool canPlayVideo(Exercise e) {
    if (isPremium) return true;
    if (planExerciseNumbers.contains(e.number)) return true;
    // A plan may use the foundation twin of a ladder rung (same video).
    return planExerciseNumbers.any(
      (n) => exerciseByNumber(n).videoNumber == e.videoNumber,
    );
  }

  bool get canStartPlan => isPremium;
}
