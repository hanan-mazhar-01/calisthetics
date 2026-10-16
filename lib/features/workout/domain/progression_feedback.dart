import '../../user/domain/completed_session.dart';

/// Decides, from how the session felt, whether to tell her she is ready for
/// the next step of a skill ladder. Pure; only claims what the data shows.
class ProgressionFeedback {
  const ProgressionFeedback._();

  /// Returns the message to show, or null when nothing is earned.
  ///
  /// Earned only for a skill session: every item on the highest rung of the
  /// skill's [ladder] (catalog numbers, easiest first) that appeared in
  /// [sessionExercises] was rated Easy. Unrated or missing efforts never count.
  static String? readyForNextStep({
    required List<int> ladder,
    required List<int> sessionExercises,
    required Map<int, Effort> efforts,
  }) {
    final top = topRungItems(
      ladder: ladder,
      sessionExercises: sessionExercises,
    );
    if (top.isEmpty) return null;
    // Already at the very top of the ladder: there is no next step to claim.
    if (ladder.isNotEmpty && top.contains(ladder.last)) return null;
    final allEasy = top.every((n) => efforts[n] == Effort.easy);
    return allEasy ? 'Ready for the next step' : null;
  }

  /// The session's exercises sitting on its highest ladder rung.
  static List<int> topRungItems({
    required List<int> ladder,
    required List<int> sessionExercises,
  }) {
    var best = -1;
    for (final n in sessionExercises) {
      final i = ladder.indexOf(n);
      if (i > best) best = i;
    }
    if (best < 0) return const [];
    return [
      for (final n in sessionExercises.toSet())
        if (ladder.indexOf(n) == best) n,
    ];
  }
}
