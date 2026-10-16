import 'onboarding_step.dart';

/// One answer to "where are you on this skill today?". [exerciseNumber] is the
/// catalog exercise the plan starts from; [stage] (0-2) is the plan stage that
/// answer maps to (Foundation / Build / Master).
class SkillAbility {
  const SkillAbility(
    this.id,
    this.label,
    this.description,
    this.stage, [
    this.exerciseNumber,
  ]);

  final String id;
  final String label;
  final String description;
  final int stage;
  final int? exerciseNumber;

  ChoiceOption toOption() =>
      ChoiceOption(id: id, label: label, description: description);
}

/// Ability answers per skill, in ladder order. Exercise numbers follow the
/// master exercise list (e.g. dips use #69-#74, toes-to-bar uses #89, pistol
/// order is #48 assisted then #49 box). Answers 1-2 start the Foundation
/// stage, 3-4 the Build stage, and the last one the Master stage.
const skillAbilities = <String, List<SkillAbility>>{
  'push-up': [
    SkillAbility('not-yet', 'Not yet', 'We start at the wall', 0, 39),
    SkillAbility(
      'wall-push-up',
      'Wall Push-Up',
      'Standing, hands on wall',
      0,
      39,
    ),
    SkillAbility(
      'incline-push-up',
      'Incline Push-Up',
      'Hands on bench or table',
      1,
      40,
    ),
    SkillAbility(
      'knee-push-up',
      'Knee Push-Up',
      'On the floor, knees down',
      1,
      41,
    ),
    SkillAbility(
      'full-push-up',
      'Standard Push-Up',
      'Chest to floor, body straight',
      2,
      42,
    ),
  ],
  'pull-up': [
    SkillAbility('not-yet', 'Not yet', "Can't hang comfortably yet", 0, 31),
    SkillAbility(
      'dead-hang',
      'Dead Hang',
      'Hold the bar, arms straight',
      0,
      32,
    ),
    SkillAbility(
      'band-assisted',
      'Band-Assisted',
      'Resistance band support',
      1,
      34,
    ),
    SkillAbility(
      'negative-pull-up',
      'Negative Pull-Up',
      'Slow lower from the top',
      1,
      35,
    ),
    SkillAbility(
      'full-pull-up',
      'Strict Pull-Up',
      'Chin clears the bar, unassisted',
      2,
      36,
    ),
  ],
  'chin-up': [
    SkillAbility('not-yet', 'Not yet', "Can't hang comfortably yet", 0, 76),
    SkillAbility(
      'dead-hang',
      'Active Hang',
      'Underhand grip, arms straight',
      0,
      76,
    ),
    SkillAbility(
      'band-assisted',
      'Band-Assisted',
      'Resistance band support',
      1,
      77,
    ),
    SkillAbility(
      'negative-chin-up',
      'Negative Chin-Up',
      'Slow lower from the top',
      1,
      79,
    ),
    SkillAbility(
      'full-chin-up',
      'Strict Chin-Up',
      'Chin clears the bar, unassisted',
      2,
      81,
    ),
  ],
  'dips': [
    SkillAbility('not-yet', 'Not yet', "Haven't tried dips", 0, 69),
    SkillAbility(
      'dip-support-hold',
      'Assisted Dip Support Hold',
      'Holding yourself up, arms straight',
      0,
      70,
    ),
    SkillAbility(
      'band-assisted',
      'Band-Assisted Dip',
      'Resistance band support',
      1,
      72,
    ),
    SkillAbility(
      'partial-range-dip',
      'Partial-Range Dip',
      'A short, controlled dip',
      1,
      73,
    ),
    SkillAbility(
      'strict-dip',
      'Strict Parallel-Bar Dip',
      'Full range, unassisted',
      2,
      74,
    ),
  ],
  'handstand': [
    SkillAbility('not-yet', 'Not yet', "Haven't tried inverting", 0, 61),
    SkillAbility('wall-walk', 'Wall Walk', 'Walking feet up the wall', 0, 63),
    SkillAbility(
      'wall-hs-chest-to-wall',
      'Chest-to-Wall Handstand',
      'Facing the wall',
      1,
      64,
    ),
    SkillAbility(
      'wall-hs-back-to-wall',
      'Back-to-Wall Handstand',
      'Facing away from the wall',
      1,
      65,
    ),
    SkillAbility(
      'freestanding',
      'Freestanding Handstand Practice',
      'No wall, balanced',
      2,
      68,
    ),
  ],
  'l-sit': [
    SkillAbility('not-yet', 'Not yet', "Haven't tried it", 0, 54),
    SkillAbility(
      'tuck-hold',
      'Tuck Support Hold',
      'Knees tucked, feet off the floor',
      0,
      56,
    ),
    SkillAbility(
      'one-leg-extended',
      'One-Leg L-Sit',
      'One leg out, one tucked',
      1,
      58,
    ),
    SkillAbility(
      'tuck-l-sit',
      'Advanced Tuck L-Sit',
      'Knees tucked, hips lifted',
      1,
      59,
    ),
    SkillAbility(
      'full-l-sit',
      'Full L-Sit',
      'Both legs extended, straight',
      2,
      60,
    ),
  ],
  'pistol-squat': [
    SkillAbility('not-yet', 'Not yet', 'Regular squats only', 0, 47),
    SkillAbility(
      'assisted-pistol',
      'Assisted Single-Leg Squat',
      'Holding a support',
      0,
      48,
    ),
    SkillAbility(
      'box-assisted',
      'Box Pistol Squat',
      'Sitting back to a box',
      1,
      49,
    ),
    SkillAbility(
      'negative-pistol',
      'Negative Pistol Squat',
      'Slow lower, assisted stand',
      1,
      51,
    ),
    SkillAbility(
      'full-pistol-squat',
      'Full Pistol Squat',
      'Unassisted, full depth',
      2,
      52,
    ),
  ],
  'toes-to-bar': [
    SkillAbility(
      'not-yet',
      'Not yet',
      "Haven't tried hanging leg raises",
      0,
      84,
    ),
    SkillAbility(
      'hanging-knee-raise',
      'Hanging Knee Raise',
      'Knees toward chest',
      0,
      84,
    ),
    SkillAbility(
      'knees-to-chest',
      'Knee Raise to Chest',
      'Full hip flexion, hanging',
      1,
      88,
    ),
    SkillAbility(
      'toes-to-bar-negative',
      'Toes-to-Bar Negative',
      'Slow, controlled lower',
      1,
      89,
    ),
    SkillAbility(
      'strict-toes-to-bar',
      'Strict Toes-to-Bar',
      'No swing, controlled',
      2,
      90,
    ),
  ],
};

/// For plans that aren't built around one skill.
const generalAbilities = <SkillAbility>[
  SkillAbility('general-new', 'Just getting started', 'New to training', 0),
  SkillAbility(
    'general-some',
    'A few basics',
    'Some squats, planks or push-ups',
    0,
  ),
  SkillAbility(
    'general-regular',
    'Comfortable',
    'I move and train fairly often',
    1,
  ),
  SkillAbility('general-strong', 'Strong', 'Training is a habit', 2),
];

/// Answers for the plan whose skill is [skillId] (null for non-skill plans).
List<SkillAbility> abilitiesFor(String? skillId) =>
    (skillId == null ? null : skillAbilities[skillId]) ?? generalAbilities;

/// The answer with [optionId] among [skillId]'s abilities, or null when it
/// doesn't belong to that list (e.g. left over from another plan).
SkillAbility? abilityById(String? skillId, String? optionId) {
  if (optionId == null) return null;
  for (final a in abilitiesFor(skillId)) {
    if (a.id == optionId) return a;
  }
  return null;
}
