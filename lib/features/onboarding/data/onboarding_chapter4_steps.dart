import '../domain/onboarding_step.dart';

/// Chapter 4 · "Your Plan": schedule, health note, plan selection and the
/// plan-specific screens, then the paywall funnel.
///
/// The plan-specific steps (plan selection, ability, encouragement, loading,
/// result, content, preview) are static shells; their real values come from
/// the user's answers via `applyDynamicContent` and `PlanBuilder`.
///
/// Removed vs. the original: the skill-aware story photo question (the plan
/// chooses the skill now, so there is nothing to ask before it), the generic
/// milestones timeline (replaced by the result projection), and the
/// Premium Intro / Free-vs-Premium pair (merged into one paywall).
final List<OnboardingStep> onboardingChapter4Steps = [
  const PartIntroStep(
    id: 'part-4-plan',
    chapter: 4,
    chapterNumberLabel: '04',
    headline: Headline('Your plan is taking ', 'shape', '.'),
    subtitle: 'Focus, schedule and a short health note.',
    ctaLabel: 'Continue',
  ),
  const FocusStep(
    id: 'focus-areas',
    chapter: 4,
    headline: Headline('Where should we ', 'focus', '?'),
    areas: [
      FocusArea(
        id: 'shoulders',
        label: 'Shoulders',
        xFraction: 0,
        yFraction: 0.125,
      ),
      FocusArea(id: 'arms', label: 'Arms', xFraction: 0.742, yFraction: 0.232),
      FocusArea(id: 'core', label: 'Core', xFraction: 0, yFraction: 0.375),
      FocusArea(id: 'back', label: 'Back', xFraction: 0.735, yFraction: 0.464),
      FocusArea(id: 'glutes', label: 'Glutes', xFraction: 0, yFraction: 0.607),
      FocusArea(id: 'legs', label: 'Legs', xFraction: 0.761, yFraction: 0.75),
    ],
  ),
  const ChoiceStep(
    id: 'time-of-day',
    chapter: 4,
    headline: Headline('When do you like to ', 'train', '?'),
    subtitle: 'We use this for your reminder.',
    layout: ChoiceLayout.list,
    selection: ChoiceSelection.single,
    options: [
      ChoiceOption(
        id: 'morning',
        label: 'Morning',
        description: 'Before the day gets going',
        glyph: 'AM',
      ),
      ChoiceOption(
        id: 'afternoon',
        label: 'Afternoon',
        description: 'A midday reset',
        glyph: 'PM',
      ),
      ChoiceOption(
        id: 'evening',
        label: 'Evening',
        description: 'To wind the day down',
        glyph: 'EV',
      ),
      ChoiceOption(
        id: 'anytime',
        label: 'No set time',
        description: 'Whenever it fits',
        glyph: '—',
      ),
    ],
  ),
  const ChoiceStep(
    id: 'days-per-week',
    chapter: 4,
    headline: Headline('How many ', 'days', ' a week?'),
    subtitle: 'Rest days are part of the plan.',
    layout: ChoiceLayout.list,
    selection: ChoiceSelection.single,
    options: [
      ChoiceOption(
        id: 'days-2',
        label: '2 days',
        description: 'Light and steady',
        glyph: '2',
      ),
      ChoiceOption(
        id: 'days-3',
        label: '3 days',
        description: 'A good rhythm to start',
        glyph: '3',
      ),
      ChoiceOption(
        id: 'days-4',
        label: '4 days',
        description: 'More practice time',
        glyph: '4',
      ),
      ChoiceOption(
        id: 'days-5',
        label: '5 days',
        description: 'A full training week',
        glyph: '5',
      ),
    ],
  ),
  const ChoiceStep(
    id: 'workout-duration',
    chapter: 4,
    headline: Headline('How long per ', 'session', '?'),
    layout: ChoiceLayout.list,
    selection: ChoiceSelection.single,
    options: [
      ChoiceOption(
        id: '10-min',
        label: '10 min',
        description: 'Micro sessions',
        glyph: "10'",
      ),
      ChoiceOption(
        id: '15-min',
        label: '15 min',
        description: 'Recommended',
        glyph: "15'",
      ),
      ChoiceOption(
        id: '20-min',
        label: '20 min',
        description: 'Full sessions',
        glyph: "20'",
      ),
    ],
  ),
  const ChoiceStep(
    id: 'intensity',
    chapter: 4,
    headline: Headline('What ', 'intensity', ' feels right?'),
    layout: ChoiceLayout.list,
    selection: ChoiceSelection.single,
    autoAdvance: false,
    options: [
      ChoiceOption(
        id: 'steady',
        label: 'Steady',
        description: 'Controlled, technique-first',
        glyph: 'L1',
        feedbackLead: 'Steady:',
        feedbackBody: 'Slow tempo and long rest — perfect for learning form.',
      ),
      ChoiceOption(
        id: 'building',
        label: 'Building',
        description: 'Challenging but sustainable',
        glyph: 'L2',
        feedbackLead: 'Building:',
        feedbackBody: 'Moderate reps, short holds, steady progress.',
      ),
      ChoiceOption(
        id: 'strong',
        label: 'Strong',
        description: 'Push close to your limit',
        glyph: 'L3',
        feedbackLead: 'Strong:',
        feedbackBody: 'Higher volume and harder variations.',
      ),
      ChoiceOption(
        id: 'athlete',
        label: 'Athlete',
        description: 'Max effort, skill work',
        glyph: 'L4',
        feedbackLead: 'Athlete:',
        feedbackBody: 'Skill blocks plus strength supersets.',
      ),
    ],
  ),
  const ChoiceStep(
    id: 'relate',
    chapter: 4,
    headline: Headline('Do any of these sound ', 'like you', '?'),
    subtitle: 'Tap any that fit, or skip ahead.',
    layout: ChoiceLayout.list,
    selection: ChoiceSelection.multi,
    autoAdvance: false,
    optional: true,
    options: [
      ChoiceOption(
        id: 'unsure-start',
        label: 'I never know where to start',
        glyph: '1',
      ),
      ChoiceOption(
        id: 'random-workouts',
        label: 'Random workouts leave me guessing',
        glyph: '2',
      ),
      ChoiceOption(
        id: 'first-pull-up',
        label: 'I want to do my first pull-up',
        glyph: '3',
      ),
      ChoiceOption(
        id: 'consistency',
        label: 'I do better with a clear schedule',
        glyph: '4',
      ),
    ],
  ),
  const PairStep(
    id: 'emotional-benefit',
    chapter: 4,
    headline: Headline('Strength changes how you ', 'feel', '.'),
  ),
  const HealthNoteStep(
    id: 'health-note',
    chapter: 4,
    headline: Headline('A quick ', 'health note', '.'),
    subtitle: 'Calesthetics is training guidance, not medical advice.',
  ),
  const PlansStep(
    id: 'plan-selection',
    chapter: 4,
    headline: Headline('Your ', 'starting plan', '.'),
    subtitle: 'Choosing a plan is choosing your skill.',
  ),
  const ChoiceStep(
    id: 'skill-ability',
    chapter: 4,
    headline: Headline('Where are you ', 'today', '?'),
    layout: ChoiceLayout.list,
    selection: ChoiceSelection.single,
    autoAdvance: false,
    options: [],
  ),
  const WinStep(
    id: 'encouragement',
    chapter: 4,
    headline: Headline('{name}, ', 'a steady start', ' is realistic.'),
    subtitle: 'A plan, one step at a time.',
  ),
  const LoadingStep(
    id: 'plan-creation',
    stages: [
      'Reading your answers',
      'Choosing your starting point',
      'Balancing upper body, core & legs',
      'Scheduling your sessions',
      'Respecting your protected areas',
      'Laying out your four phases',
    ],
  ),
  const RevealStep(
    id: 'personalized-result',
    ctaLabel: 'See my plan',
    stats: [
      PlanStat(value: '4', label: 'Weeks'),
      PlanStat(value: '-', label: 'Sessions / week'),
      PlanStat(value: '-', label: 'Minutes'),
      PlanStat(value: '-', label: 'Equipment'),
    ],
  ),
  const PlanContentStep(
    id: 'plan-content',
    headline: Headline("What's ", 'inside', '.'),
    rows: [],
    muscleAllocations: [],
    ctaLabel: 'Continue',
  ),
  const PlanPreviewStep(
    id: 'plan-preview',
    headline: Headline('Four ', 'phases', '.'),
    phases: [],
    ctaLabel: 'Get my plan',
  ),
  const MosaicStep(
    id: 'train-anywhere',
    headline: Headline('Train ', 'anywhere', '.'),
    ctaLabel: 'Continue',
    tiles: [
      MosaicTile(
        label: 'Living room',
        photoPrompt: 'Push-up at home',
        height: 230,
      ),
      MosaicTile(
        label: 'Park',
        photoPrompt: 'Pull-up on a secure bar',
        height: 280,
      ),
      MosaicTile(label: 'Wall', photoPrompt: 'Wall handstand', height: 260),
      MosaicTile(
        label: 'Chair',
        photoPrompt: 'Chair/Box Squat at home',
        height: 210,
      ),
    ],
  ),
  const MosaicStep(
    id: 'exercise-library',
    headline: Headline('115 exercises, ', '98 coached videos', '.'),
    ctaLabel: 'Continue',
    tiles: [
      MosaicTile(
        label: 'Push-Up',
        photoPrompt: 'Woman, full push-up',
        height: 250,
      ),
      MosaicTile(
        label: 'Pull-Up',
        photoPrompt: 'Woman, pull-up on bar',
        height: 200,
      ),
      MosaicTile(
        label: 'Handstand',
        photoPrompt: 'Woman, wall handstand',
        height: 200,
      ),
      MosaicTile(
        label: 'L-Sit',
        photoPrompt: 'Woman, L-sit on parallettes',
        height: 250,
      ),
      MosaicTile(
        label: 'Pistol Squat',
        photoPrompt: 'Woman, pistol squat',
        height: 200,
      ),
      MosaicTile(
        label: 'Dips',
        photoPrompt: 'Woman, parallel bar dip',
        height: 200,
      ),
    ],
  ),
  const PaywallStep(id: 'paywall'),
  const AccountStep(id: 'account'),
];
