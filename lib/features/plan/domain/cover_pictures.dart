import '../../exercises/domain/exercise_lookup.dart';
import 'plan_timeline.dart';

/// Picks the picture for each day's card from that day's own exercises, so
/// the cards don't all show the same image: every day takes the exercise of
/// its session that has been pictured least so far (ties go to the earliest
/// one in the session, which keeps the day's own lead exercise first), and a
/// picture never repeats the previous day's while another choice exists.
/// Keyed by [TimelineDay.dayNumber].
Map<int, int> coverPictures(List<TimelineDay> days) {
  final used = <int, int>{}; // video number -> times pictured
  final covers = <int, int>{};
  int? previousVideo;
  for (final day in days) {
    final session = day.session;
    final options = <int>[
      session.cover,
      ...session.ownNumbers,
      // Sessions built elsewhere (no own list) fall back to every exercise.
      if (session.ownNumbers.isEmpty)
        for (final item in session.items) item.exerciseNumber,
    ];
    final seen = <int>{};
    int? best;
    var bestScore = 1 << 30;
    for (final n in options) {
      final video = exerciseByNumber(n).videoNumber;
      if (!seen.add(video)) continue;
      final score = (used[video] ?? 0) * 10 + (video == previousVideo ? 5 : 0);
      if (score < bestScore) {
        bestScore = score;
        best = n;
      }
    }
    final pick = best ?? session.cover;
    final video = exerciseByNumber(pick).videoNumber;
    used[video] = (used[video] ?? 0) + 1;
    previousVideo = video;
    covers[day.dayNumber] = pick;
  }
  return covers;
}
