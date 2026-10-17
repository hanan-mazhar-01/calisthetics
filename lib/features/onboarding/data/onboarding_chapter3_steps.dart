import '../domain/onboarding_step.dart';

/// Chapter 3 · "Fitness": experience, endurance, plank test, projection.
///
/// The bar-rating "Fitness Level" screen was removed: it only re-asked
/// Beginner/Novice/Intermediate/Advanced, already derivable from Training
/// Experience — asking twice added a screen without adding information.
/// The "Where is your strength today?" step was merged into Training
/// experience. Squat Test was removed for the same reason (a second generic rep-count
/// self-report alongside Endurance and the skill-ability question).
final List<OnboardingStep> onboardingChapter3Steps = [
  const PartIntroStep(
    id: 'part-3-fitness',
    chapter: 3,
    chapterNumberLabel: '03',
    headline: Headline("Let's read your ", 'strength signals', '.'),
    subtitle:
        'A couple of honest answers and a plank test. No equipment needed.',
    ctaLabel: 'Start',
  ),
  const ChoiceStep(
    id: 'training-experience',
    chapter: 3,
    headline: Headline('What\'s your ', 'fitness level', '?'),
    layout: ChoiceLayout.slider,
    selection: ChoiceSelection.single,
    autoAdvance: false,
    options: [
      ChoiceOption(
        id: 'beginner',
        label: 'Beginner',
        description: 'Never trained regularly',
        glyph: 'B',
      ),
      ChoiceOption(
        id: 'some-experience',
        label: 'Some experience',
        description: 'On and off',
        glyph: 'S',
      ),
      ChoiceOption(
        id: 'intermediate',
        label: 'Intermediate',
        description: '2–3× a week',
        glyph: 'I',
      ),
      ChoiceOption(
        id: 'advanced',
        label: 'Advanced',
        description: 'Years of training',
        glyph: 'A',
      ),
    ],
  ),
  const ChoiceStep(
    id: 'endurance',
    chapter: 3,
    headline: Headline('After a brisk ', '10-min walk', '?'),
    layout: ChoiceLayout.list,
    selection: ChoiceSelection.single,
    autoAdvance: false,
    options: [
      ChoiceOption(
        id: 'out-of-breath',
        imageKey: 'onboarding/fitness/out-of-breath',
        label: 'Out of breath',
        glyph: '1',
        feedbackLead: 'Good to know.',
        feedbackBody: "We'll build your engine with short, steady rounds.",
      ),
      ChoiceOption(
        id: 'a-bit-tired',
        imageKey: 'onboarding/fitness/a-bit-tired',
        label: 'A bit tired',
        glyph: '2',
        feedbackLead: 'Solid.',
        feedbackBody: 'Perfect base for circuits with longer rest.',
      ),
      ChoiceOption(
        id: 'feeling-easy',
        imageKey: 'onboarding/fitness/feeling-easy',
        label: 'Feeling easy',
        glyph: '3',
        feedbackLead: 'Strong engine.',
        feedbackBody: 'We can add tempo and density early.',
      ),
    ],
  ),
  const PlankStep(
    id: 'plank-test',
    chapter: 3,
    headline: Headline('Hold a ', 'plank', '. Go.'),
    subtitle: 'Forearms down, body straight. Tap start, hold, tap stop.',
  ),
  const CurveStep(
    id: 'personalized-projection',
    chapter: 3,
    headline: Headline('A plank target to ', 'aim for', '.'),
    xAxisLabels: ['Today', 'Wk 2', 'Wk 4', 'Wk 8'],
    points: [
      CurvePoint(
        xFraction: 0.10,
        yFraction: 0.84,
        label: 'Today',
        imageKey: 'onboarding/goal-screen/emoji-2',
      ),
      CurvePoint(
        xFraction: 0.50,
        yFraction: 0.54,
        label: 'Wk 4',
        imageKey: 'onboarding/goal-screen/emoji',
      ),
      CurvePoint(
        xFraction: 0.92,
        yFraction: 0.14,
        label: 'Target',
        emphasized: true,
        imageKey: 'onboarding/goal-screen/emoji-1',
      ),
    ],
    footer: 'A target, not a promise. Regular practice builds it, and consistency matters more than intensity.',
  ),
  const CompareStep(
    id: 'why-calesthetics-different',
    chapter: 3,
    headline: Headline('Built as a ', 'progression', '.'),
    leftItems: [
      'Random workouts',
      'Same moves for everyone',
      'No clear next step',
      'Hard to see progress',
    ],
    rightItems: [
      'A ladder of calisthenics skills',
      'Regressions for your level',
      'Always a next rung',
      'Progress you can see',
    ],
  ),
];
