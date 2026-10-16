import '../../user/domain/completed_session.dart';
import '../../user/domain/plank_attempt.dart';
import '../../user/domain/user_stats.dart';

/// Which tab of the Achievements page a medal sits on.
enum AchievementCategory {
  streak('STREAK'),
  workout('WORKOUT'),
  time('TIME'),
  skill('SKILLS');

  const AchievementCategory(this.label);
  final String label;
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.current,
    required this.target,
    this.category = AchievementCategory.workout,
    this.number = '',
    this.unit = '',
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final int current;
  final int target;
  final AchievementCategory category;

  /// Big figure on the medal ("7") and the small caption beside it ("DAYS").
  final String number;
  final String unit;

  /// The day the target was first reached, from her own history; null while
  /// locked.
  final DateTime? unlockedAt;

  bool get unlocked => current >= target;
  double get progress => (current / target).clamp(0.0, 1.0);
}

/// Computes achievements from real data only. Pure.
class AchievementEvaluator {
  const AchievementEvaluator();

  List<Achievement> evaluate({
    required List<CompletedSession> history,
    required UserStats stats,
    required Map<String, int> records,
    List<PlankAttempt> plank = const [],
    Set<int> restWeekdays = const {},
  }) {
    final distinct = {for (final s in history) ...s.exerciseNumbers}.length;
    final bestPlank = records['plankSeconds'] ?? 0;

    // The metric after each finished workout, oldest first, so every medal can
    // say the day she earned it.
    final ordered = [...history]
      ..sort((a, b) => a.finishedAt.compareTo(b.finishedAt));
    final workoutsAt = <DateTime>[];
    final streakAt = <int>[];
    final minutesAt = <int>[];
    final exercisesAt = <int>[];
    final seen = <int>{};
    for (var k = 1; k <= ordered.length; k++) {
      final upTo = ordered.take(k).toList();
      final last = upTo.last.finishedAt;
      final s = UserStats.from(upTo, today: last, restWeekdays: restWeekdays);
      workoutsAt.add(last);
      streakAt.add(s.longestStreak);
      minutesAt.add(s.totalMinutes);
      seen.addAll(upTo.last.exerciseNumbers);
      exercisesAt.add(seen.length);
    }

    DateTime? firstReached(List<int> metric, int target) {
      for (var i = 0; i < metric.length; i++) {
        if (metric[i] >= target) return workoutsAt[i];
      }
      return null;
    }

    DateTime? plankReached(int target) {
      final byTime = [...plank]..sort((a, b) => a.at.compareTo(b.at));
      for (final p in byTime) {
        if (p.seconds >= target) return p.at;
      }
      return null;
    }

    Achievement a(
      String id,
      AchievementCategory cat,
      String title,
      String desc,
      int cur,
      int target,
      String number,
      String unit,
      DateTime? Function() reached,
    ) {
      final unlocked = cur >= target;
      return Achievement(
        id: id,
        title: title,
        description: desc,
        current: cur > target ? target : cur,
        target: target,
        category: cat,
        number: number,
        unit: unit,
        unlockedAt: unlocked ? reached() : null,
      );
    }

    const streak = AchievementCategory.streak;
    const workout = AchievementCategory.workout;
    const time = AchievementCategory.time;
    const skill = AchievementCategory.skill;
    final longest = stats.longestStreak;
    final n = stats.workouts;
    final mins = stats.totalMinutes;
    DateTime? streakDay(int t) => firstReached(streakAt, t);
    DateTime? workoutN(int t) =>
        t <= workoutsAt.length ? workoutsAt[t - 1] : null;
    DateTime? minutesDay(int t) => firstReached(minutesAt, t);

    return [
      a(
        'day-1',
        streak,
        'First Day',
        'Finish a workout.',
        longest,
        1,
        '1',
        'DAY',
        () => streakDay(1),
      ),
      a(
        'day-2',
        streak,
        'Second Day',
        'Train 2 days in a row.',
        longest,
        2,
        '2',
        'DAYS',
        () => streakDay(2),
      ),
      a(
        'streak-3',
        streak,
        'Three in a row',
        'Train 3 days in a row.',
        longest,
        3,
        '3',
        'DAYS',
        () => streakDay(3),
      ),
      a(
        'streak-7',
        streak,
        'Full week',
        'Train 7 days in a row.',
        longest,
        7,
        '7',
        'DAYS',
        () => streakDay(7),
      ),
      a(
        'streak-14',
        streak,
        'Two weeks',
        'Train 14 days in a row.',
        longest,
        14,
        '14',
        'DAYS',
        () => streakDay(14),
      ),
      a(
        'streak-30',
        streak,
        'Thirty days',
        'Train 30 days in a row.',
        longest,
        30,
        '30',
        'DAYS',
        () => streakDay(30),
      ),
      a(
        'streak-100',
        streak,
        'One hundred days',
        'Train 100 days in a row.',
        longest,
        100,
        '100',
        'DAYS',
        () => streakDay(100),
      ),
      a(
        'first-workout',
        workout,
        'First step',
        'Finish your first workout.',
        n,
        1,
        '1',
        'WORKOUT',
        () => workoutN(1),
      ),
      a(
        'workouts-5',
        workout,
        'Five down',
        'Finish 5 workouts.',
        n,
        5,
        '5',
        'WORKOUTS',
        () => workoutN(5),
      ),
      a(
        'workouts-10',
        workout,
        'Ten down',
        'Finish 10 workouts.',
        n,
        10,
        '10',
        'WORKOUTS',
        () => workoutN(10),
      ),
      a(
        'workouts-25',
        workout,
        'Twenty-five',
        'Finish 25 workouts.',
        n,
        25,
        '25',
        'WORKOUTS',
        () => workoutN(25),
      ),
      a(
        'workouts-50',
        workout,
        'Fifty',
        'Finish 50 workouts.',
        n,
        50,
        '50',
        'WORKOUTS',
        () => workoutN(50),
      ),
      a(
        'workouts-100',
        workout,
        'One hundred',
        'Finish 100 workouts.',
        n,
        100,
        '100',
        'WORKOUTS',
        () => workoutN(100),
      ),
      a(
        'minutes-30',
        time,
        '30 minutes',
        'Train for 30 minutes in total.',
        mins,
        30,
        '30',
        'MIN',
        () => minutesDay(30),
      ),
      a(
        'minutes-100',
        time,
        '100 minutes',
        'Train for 100 minutes in total.',
        mins,
        100,
        '100',
        'MIN',
        () => minutesDay(100),
      ),
      a(
        'minutes-300',
        time,
        '300 minutes',
        'Train for 300 minutes in total.',
        mins,
        300,
        '300',
        'MIN',
        () => minutesDay(300),
      ),
      a(
        'minutes-600',
        time,
        '600 minutes',
        'Train for 600 minutes in total.',
        mins,
        600,
        '600',
        'MIN',
        () => minutesDay(600),
      ),
      a(
        'minutes-1000',
        time,
        '1000 minutes',
        'Train for 1000 minutes in total.',
        mins,
        1000,
        '1000',
        'MIN',
        () => minutesDay(1000),
      ),
      a(
        'plank-30',
        skill,
        'Plank 30',
        'Hold a plank for 30 seconds.',
        bestPlank,
        30,
        '30',
        'SEC',
        () => plankReached(30),
      ),
      a(
        'plank-60',
        skill,
        'Plank 60',
        'Hold a plank for 60 seconds.',
        bestPlank,
        60,
        '60',
        'SEC',
        () => plankReached(60),
      ),
      a(
        'explorer',
        skill,
        'Explorer',
        'Train 20 different exercises.',
        distinct,
        20,
        '20',
        'MOVES',
        () => firstReached(exercisesAt, 20),
      ),
      a(
        'explorer-50',
        skill,
        'Half the library',
        'Train 50 different exercises.',
        distinct,
        50,
        '50',
        'MOVES',
        () => firstReached(exercisesAt, 50),
      ),
    ];
  }
}
