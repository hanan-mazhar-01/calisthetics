import '../../exercises/domain/exercise.dart';

/// THE one place that decides what a free user can open. Owner has not yet
/// confirmed the rule, so it lives here and nowhere else.
///
/// Default rule:
///  * every exercise page is visible to everyone;
///  * video on a skill-ladder rung that is not part of the user's own plan
///    needs premium (foundation / warm-up videos are free);
///  * exercises in the user's own plan always play;
///  * starting a plan needs premium.
class ExerciseAccessPolicy {
  const ExerciseAccessPolicy({
    required this.isPremium,
    this.planExerciseNumbers = const {},
  });

  final bool isPremium;

  /// Catalog numbers used by the user's active plan.
  final Set<int> planExerciseNumbers;

  bool canViewPage(Exercise e) => true;

  /// Paywall testing disabled: every video plays directly.
  bool canPlayVideo(Exercise e) => true;

  bool get canStartPlan => true;
}
