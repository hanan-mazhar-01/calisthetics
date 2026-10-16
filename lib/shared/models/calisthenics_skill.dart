import '../../features/onboarding/domain/onboarding_step.dart';

/// The 8 real skill categories Calesthetics has video content for (10 videos each,
/// 80 total). Onboarding's skill-selection and every downstream
/// skill-flavored screen (ability question, encouragement, projections,
/// plan preview) reads from this catalog — there is exactly one source of
/// truth for "what skills does this app actually teach."
class CalisthenicsSkill {
  const CalisthenicsSkill({
    required this.id,
    required this.label,
    required this.tagline,
    required this.imagePrompt,
    required this.abilityLevels,
    required this.encouragementOutcome,
    required this.progressionStages,
    required this.storyQuestion,
    required this.storyPhotoPrompt,
  });

  final String id;
  final String label;

  /// Short descriptor shown under the label in selection grids ("Balance & power").
  final String tagline;
  final String imagePrompt;

  /// 5 ascending self-assessment levels, "haven't started" to "full rep".
  final List<ChoiceOption> abilityLevels;

  /// Fills "{name}, your first ___ is realistic." on the Encouragement screen.
  final String encouragementOutcome;

  /// 3 progression-chart labels (early / mid / goal) for curve screens.
  final List<String> progressionStages;

  final String storyQuestion;
  final String storyPhotoPrompt;
}

const calisthenicsSkills = [
  CalisthenicsSkill(
    id: 'push-up',
    label: 'Push-Up',
    tagline: 'The foundation',
    imagePrompt: 'Woman, full push-up',
    abilityLevels: [
      ChoiceOption(
        id: 'not-yet',
        label: 'Not yet',
        description: 'We start at the wall',
      ),
      ChoiceOption(
        id: 'wall-push-up',
        label: 'Wall Push-Up',
        description: 'Standing, hands on wall',
      ),
      ChoiceOption(
        id: 'incline-push-up',
        label: 'Incline Push-Up',
        description: 'Hands on bench or table',
      ),
      ChoiceOption(
        id: 'knee-push-up',
        label: 'Knee Push-Up',
        description: 'On the floor, knees down',
      ),
      ChoiceOption(
        id: 'full-push-up',
        label: 'Full Push-Up',
        description: 'Chest to floor, body straight',
      ),
    ],
    encouragementOutcome: 'a full push-up',
    progressionStages: ['Incline', 'Knee', 'Full rep'],
    storyQuestion: 'Want to do a full push-up with perfect form?',
    storyPhotoPrompt: 'Woman doing a full push-up, outdoors',
  ),
  CalisthenicsSkill(
    id: 'pull-up',
    label: 'Pull-Up',
    tagline: 'Back strength',
    imagePrompt: 'Woman, pull-up on bar',
    abilityLevels: [
      ChoiceOption(
        id: 'not-yet',
        label: 'Not yet',
        description: "Can't hang comfortably yet",
      ),
      ChoiceOption(
        id: 'dead-hang',
        label: 'Dead Hang',
        description: 'Hold the bar, arms straight',
      ),
      ChoiceOption(
        id: 'band-assisted',
        label: 'Band-Assisted',
        description: 'Resistance band support',
      ),
      ChoiceOption(
        id: 'negative-pull-up',
        label: 'Negative Pull-Up',
        description: 'Slow lower from the top',
      ),
      ChoiceOption(
        id: 'full-pull-up',
        label: 'Full Pull-Up',
        description: 'Chin clears the bar, unassisted',
      ),
    ],
    encouragementOutcome: 'your first pull-up',
    progressionStages: ['Dead hang', 'Negative', 'Full rep'],
    storyQuestion: 'Want to do your first unassisted pull-up?',
    storyPhotoPrompt: 'Woman doing a pull-up on a bar, outdoors',
  ),
  CalisthenicsSkill(
    id: 'chin-up',
    label: 'Chin-Up',
    tagline: 'Biceps & back',
    imagePrompt: 'Woman, chin-up on bar',
    abilityLevels: [
      ChoiceOption(
        id: 'not-yet',
        label: 'Not yet',
        description: "Can't hang comfortably yet",
      ),
      ChoiceOption(
        id: 'dead-hang',
        label: 'Dead Hang',
        description: 'Underhand grip, arms straight',
      ),
      ChoiceOption(
        id: 'band-assisted',
        label: 'Band-Assisted',
        description: 'Resistance band support',
      ),
      ChoiceOption(
        id: 'negative-chin-up',
        label: 'Negative Chin-Up',
        description: 'Slow lower from the top',
      ),
      ChoiceOption(
        id: 'full-chin-up',
        label: 'Full Chin-Up',
        description: 'Chin clears the bar, unassisted',
      ),
    ],
    encouragementOutcome: 'your first chin-up',
    progressionStages: ['Dead hang', 'Negative', 'Full rep'],
    storyQuestion: 'Want to do your first chin-up?',
    storyPhotoPrompt: 'Woman doing a chin-up on a bar, outdoors',
  ),
  CalisthenicsSkill(
    id: 'dips',
    label: 'Dips',
    tagline: 'Arm power',
    imagePrompt: 'Woman, parallel bar dip',
    abilityLevels: [
      ChoiceOption(
        id: 'not-yet',
        label: 'Not yet',
        description: "Haven't tried dips",
      ),
      ChoiceOption(
        id: 'bench-dips',
        label: 'Bench Dips',
        description: 'Hands on a bench behind you',
      ),
      ChoiceOption(
        id: 'band-assisted',
        label: 'Band-Assisted',
        description: 'Resistance band support',
      ),
      ChoiceOption(
        id: 'negative-dip',
        label: 'Negative Dip',
        description: 'Slow lower from the top',
      ),
      ChoiceOption(
        id: 'full-dip',
        label: 'Full Dip',
        description: 'Full range, unassisted',
      ),
    ],
    encouragementOutcome: 'a full dip',
    progressionStages: ['Bench dips', 'Negative', 'Full rep'],
    storyQuestion: 'Want to master parallel bar dips?',
    storyPhotoPrompt: 'Woman doing a dip on parallel bars, outdoors',
  ),
  CalisthenicsSkill(
    id: 'handstand',
    label: 'Handstand',
    tagline: 'Balance & power',
    imagePrompt: 'Woman, wall handstand',
    abilityLevels: [
      ChoiceOption(
        id: 'not-yet',
        label: 'Not yet',
        description: "Haven't tried inverting",
      ),
      ChoiceOption(
        id: 'wall-walk',
        label: 'Wall Walk',
        description: 'Walking feet up the wall',
      ),
      ChoiceOption(
        id: 'wall-hs-chest-to-wall',
        label: 'Wall HS · Chest to Wall',
        description: 'Facing the wall',
      ),
      ChoiceOption(
        id: 'wall-hs-back-to-wall',
        label: 'Wall HS · Back to Wall',
        description: 'Facing away from the wall',
      ),
      ChoiceOption(
        id: 'freestanding',
        label: 'Freestanding',
        description: 'No wall, balanced',
      ),
    ],
    encouragementOutcome: 'a freestanding handstand',
    progressionStages: ['Wall walk', 'Wall HS', 'Freestanding'],
    storyQuestion: 'Want to hold your first freestanding handstand?',
    storyPhotoPrompt: 'Woman holding a wall handstand, sunlit studio',
  ),
  CalisthenicsSkill(
    id: 'l-sit',
    label: 'L-Sit',
    tagline: 'Core control',
    imagePrompt: 'Woman, L-sit on parallettes',
    abilityLevels: [
      ChoiceOption(
        id: 'not-yet',
        label: 'Not yet',
        description: "Haven't tried it",
      ),
      ChoiceOption(
        id: 'tuck-hold',
        label: 'Tuck Hold',
        description: 'Knees tucked, feet off the floor',
      ),
      ChoiceOption(
        id: 'tuck-l-sit',
        label: 'Tuck L-Sit',
        description: 'Knees tucked, hips lifted',
      ),
      ChoiceOption(
        id: 'one-leg-extended',
        label: 'One-Leg Extended',
        description: 'One leg out, one tucked',
      ),
      ChoiceOption(
        id: 'full-l-sit',
        label: 'Full L-Sit',
        description: 'Both legs extended, straight',
      ),
    ],
    encouragementOutcome: 'a full L-sit',
    progressionStages: ['Tuck hold', 'Tuck L-sit', 'Full L-sit'],
    storyQuestion: 'Want to hold a full L-sit?',
    storyPhotoPrompt: 'Woman holding an L-sit on parallettes, studio',
  ),
  CalisthenicsSkill(
    id: 'pistol-squat',
    label: 'Pistol Squat',
    tagline: 'Single-leg strength',
    imagePrompt: 'Woman, pistol squat',
    abilityLevels: [
      ChoiceOption(
        id: 'not-yet',
        label: 'Not yet',
        description: 'Regular squats only',
      ),
      ChoiceOption(
        id: 'box-assisted',
        label: 'Box-Assisted',
        description: 'Sitting back to a box',
      ),
      ChoiceOption(
        id: 'assisted-pistol',
        label: 'Assisted Pistol',
        description: 'Holding a support',
      ),
      ChoiceOption(
        id: 'negative-pistol',
        label: 'Negative Pistol',
        description: 'Slow lower, assisted stand',
      ),
      ChoiceOption(
        id: 'full-pistol-squat',
        label: 'Full Pistol Squat',
        description: 'Unassisted, full depth',
      ),
    ],
    encouragementOutcome: 'a full pistol squat',
    progressionStages: ['Box squat', 'Negative', 'Full rep'],
    storyQuestion: 'Want to nail a full pistol squat?',
    storyPhotoPrompt: 'Woman doing a pistol squat, outdoors',
  ),
  CalisthenicsSkill(
    id: 'toes-to-bar',
    label: 'Toes-to-Bar',
    tagline: 'Core & grip',
    imagePrompt: 'Woman, toes-to-bar on bar',
    abilityLevels: [
      ChoiceOption(
        id: 'not-yet',
        label: 'Not yet',
        description: "Haven't tried hanging leg raises",
      ),
      ChoiceOption(
        id: 'hanging-knee-raise',
        label: 'Hanging Knee Raise',
        description: 'Knees toward chest',
      ),
      ChoiceOption(
        id: 'knees-to-chest',
        label: 'Knees-to-Chest',
        description: 'Full hip flexion, hanging',
      ),
      ChoiceOption(
        id: 'kipping-toes-to-bar',
        label: 'Kipping Toes-to-Bar',
        description: 'Using swing momentum',
      ),
      ChoiceOption(
        id: 'strict-toes-to-bar',
        label: 'Strict Toes-to-Bar',
        description: 'No kip, controlled',
      ),
    ],
    encouragementOutcome: 'strict toes-to-bar',
    progressionStages: ['Knee raise', 'Kipping', 'Strict'],
    storyQuestion: 'Want to string together strict toes-to-bar?',
    storyPhotoPrompt: 'Woman doing toes-to-bar on a bar, gym',
  ),
];
