import '../../exercises/domain/exercise.dart';

/// THE one place that decides what a free user can open in Discover.
///
///  * Every Discover exercise video needs Premium, whether or not the
///    exercise is in the user's own plan (the plan's workouts play in the
///    workout player as usual, and are not part of Discover);
///  * exercise pages stay visible to everyone (with a lock on the video);
///  * starting plans beyond the free one needs Premium.
class ExerciseAccessPolicy {
  const ExerciseAccessPolicy({required this.isPremium});

  final bool isPremium;

  bool canViewPage(Exercise e) => true;

  bool canPlayVideo(Exercise e) => isPremium;

  bool get canStartPlan => isPremium;
}
