import '../../../profile/domain/achievement_evaluator.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Oct 13, 2026".
String medalDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

/// What the celebration screen says. Built from the medal's own numbers.
String celebrationText(Achievement a) => switch (a.category) {
  AchievementCategory.streak =>
    a.target == 1
        ? 'You made it here. First steps count the most, so keep this going.'
        : '${a.target} days in a row. Showing up is the hard part.',
  AchievementCategory.workout =>
    a.target == 1
        ? 'Your first workout is done. Every session adds up.'
        : '${a.target} workouts finished. Every session adds up.',
  AchievementCategory.time =>
    '${a.target} minutes of training so far. That is time you gave yourself.',
  AchievementCategory.skill => switch (a.id) {
    'plank-30' || 'plank-60' =>
      'You held a plank for ${a.target} seconds. Strong and steady.',
    _ => '${a.target} different exercises tried. Keep exploring.',
  },
};
