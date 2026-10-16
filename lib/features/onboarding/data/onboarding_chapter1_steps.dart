import '../domain/onboarding_step.dart';

/// Chapter 1 · "Goal" — welcome, age, goals, space and equipment.
/// Copy is transcribed verbatim from the Claude Design handoff (`S` array,
/// entries 0-10) so onboarding matches the approved design word-for-word.
/// `.ref` duplicate entries (pre-selected-state previews) are intentionally
/// not modeled as separate steps — they're the same screen mid-interaction.
final List<OnboardingStep> onboardingChapter1Steps = [
  const WelcomeStep(id: 'welcome'),
  const ChoiceStep(
    id: 'age',
    chapter: 1,
    headline: Headline('How ', 'old', ' are you?'),
    subtitle: 'Strength adapts at every age. This tunes volume and recovery.',
    layout: ChoiceLayout.grid,
    selection: ChoiceSelection.single,
    options: [
      ChoiceOption(
        id: '18-24',
        label: '18–24',
        imagePrompt: 'Portrait, woman 18–24',
      ),
      ChoiceOption(
        id: '25-34',
        label: '25–34',
        imagePrompt: 'Portrait, woman 25–34',
      ),
      ChoiceOption(
        id: '35-44',
        label: '35–44',
        imagePrompt: 'Portrait, woman 35–44',
      ),
      ChoiceOption(
        id: '45-54',
        label: '45–54',
        imagePrompt: 'Portrait, woman 45–54',
      ),
      ChoiceOption(
        id: '55-64',
        label: '55–64',
        imagePrompt: 'Portrait, woman 55–64',
      ),
      ChoiceOption(
        id: '65-plus',
        label: '65+',
        imagePrompt: 'Portrait, woman 65+',
      ),
    ],
  ),
  const PartIntroStep(
    id: 'part-1-goal',
    chapter: 1,
    chapterNumberLabel: '01',
    headline: Headline("Let's set your ", 'goal', '.'),
    subtitle: 'Four short chapters. Every answer shapes your plan.',
    ctaLabel: 'Begin',
  ),
  const ChoiceStep(
    id: 'main-goal',
    chapter: 1,
    headline: Headline('What is your ', 'main goal', '?'),
    layout: ChoiceLayout.list,
    selection: ChoiceSelection.single,
    options: [
      ChoiceOption(
        id: 'get-stronger',
        label: 'Get Stronger',
        description: 'Lift your own bodyweight with control',
        imagePrompt: 'Get Stronger',
      ),
      ChoiceOption(
        id: 'fit-tone-my-body',
        label: 'Fit & Tone My Body',
        description: 'Strong legs, core and arms',
        imagePrompt: 'Fit & Tone My Body',
      ),
      ChoiceOption(
        id: 'improve-fitness',
        label: 'Improve Fitness',
        description: 'More energy, better endurance',
        imagePrompt: 'Improve Fitness',
      ),
      ChoiceOption(
        id: 'master-calisthenics-skills',
        label: 'Master Calisthenics Skills',
        description: 'Handstands, L-sits, pull-ups',
        imagePrompt: 'Master Calisthenics Skills',
      ),
    ],
  ),
  const ChoiceStep(
    id: 'additional-goals',
    chapter: 1,
    headline: Headline('Anything ', 'else', '?'),
    subtitle: 'Pick all that matter.',
    layout: ChoiceLayout.list,
    selection: ChoiceSelection.multi,
    autoAdvance: false,
    options: [
      ChoiceOption(
        id: 'stronger-upper-body',
        label: 'Stronger Upper Body',
        imagePrompt: 'Stronger Upper Body',
      ),
      ChoiceOption(
        id: 'stronger-core',
        label: 'Stronger Core',
        imagePrompt: 'Stronger Core',
      ),
      ChoiceOption(
        id: 'stronger-legs',
        label: 'Stronger Legs',
        imagePrompt: 'Stronger Legs',
      ),
      ChoiceOption(
        id: 'better-mobility',
        label: 'Better Mobility',
        imagePrompt: 'Better Mobility',
      ),
      ChoiceOption(
        id: 'better-balance',
        label: 'Better Balance',
        imagePrompt: 'Better Balance',
      ),
      ChoiceOption(
        id: 'feel-more-confident',
        label: 'Feel More Confident',
        imagePrompt: 'Feel More Confident',
      ),
    ],
  ),
  const CurveStep(
    id: 'potential',
    chapter: 1,
    headline: Headline('Skills grow ', 'one rung', ' at a time.'),
    xAxisLabels: ['Wk 1', 'Wk 4', 'Wk 8', 'Wk 12'],
    points: [
      CurvePoint(xFraction: 0.42, yFraction: 0.60, label: 'Strength'),
      CurvePoint(
        xFraction: 0.92,
        yFraction: 0.14,
        label: 'Your skill',
        emphasized: true,
      ),
    ],
    footer: 'Calisthenics is a ladder. Each rung is a movement you can master before the next — we build every rung for you.',
  ),
  const ChoiceStep(
    id: 'training-space',
    chapter: 1,
    headline: Headline('Where will you ', 'train', '?'),
    layout: ChoiceLayout.list,
    selection: ChoiceSelection.single,
    options: [
      ChoiceOption(
        id: 'home',
        label: 'Home',
        description: 'Floor, wall, a sturdy chair',
        imagePrompt: 'Home',
      ),
      ChoiceOption(
        id: 'gym',
        label: 'Gym',
        description: 'Pull-up bar, parallel bars',
        imagePrompt: 'Gym',
      ),
      ChoiceOption(
        id: 'both',
        label: 'Both',
        description: 'A mix of home and gym or park',
        imagePrompt: 'Both',
      ),
    ],
  ),
  const ChoiceStep(
    id: 'equipment',
    chapter: 1,
    headline: Headline('What do you have ', 'to hand', '?'),
    subtitle:
        'Pick everything you can use. A wall and the floor are always assumed.',
    layout: ChoiceLayout.list,
    selection: ChoiceSelection.multi,
    autoAdvance: false,
    exclusiveOptionId: 'none',
    options: [
      ChoiceOption(
        id: 'none',
        label: 'None',
        description: 'Just me and the floor',
        glyph: '—',
      ),
      ChoiceOption(
        id: 'pull-up-bar',
        label: 'Pull-up bar',
        description: 'A secure, fixed pull-up bar',
        glyph: 'P',
      ),
      ChoiceOption(
        id: 'parallettes',
        label: 'Parallettes or dip bars',
        description: 'Low bars or parallel bars',
        glyph: 'D',
      ),
      ChoiceOption(
        id: 'resistance-band',
        label: 'Resistance band',
        description: 'For assisted pulls and dips',
        glyph: 'R',
      ),
      ChoiceOption(
        id: 'chair-box',
        label: 'Sturdy chair or box',
        description: 'Something stable to step or sit back to',
        glyph: 'C',
      ),
    ],
  ),
];
