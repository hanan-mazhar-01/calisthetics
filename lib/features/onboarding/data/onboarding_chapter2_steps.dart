import '../domain/onboarding_step.dart';

/// Chapter 2 · "About You": name and areas to protect.
///
/// "Typical day" was removed: PlanBuilder doesn't use it. The ability
/// question moved to Part 4 (after plan selection, because the plan decides
/// which skill it asks about) and Encouragement went with it.
///
/// Height/Weight/Hydration/Sleep/Lifestyle were removed: none of them feed
/// the training plan today, and collecting them anyway isn't justified.
/// Physical Considerations (pregnancy/postpartum/menopause) was removed too
/// — Calesthetics doesn't have reviewed programs for those life stages, so asking
/// implied a medical-adjacency claim the app can't back up. Areas to Protect
/// (a plain injury/joint-protection list) covers the legitimate need.
final List<OnboardingStep> onboardingChapter2Steps = [
  const PartIntroStep(
    id: 'part-2-you',
    chapter: 2,
    chapterNumberLabel: '02',
    headline: Headline('A little about ', 'you', '.'),
    subtitle: 'This shapes your starting point — never to judge.',
    ctaLabel: 'Continue',
  ),
  const NameStep(
    id: 'name',
    chapter: 2,
    headline: Headline('What should we ', 'call you', '?'),
  ),
  const ChoiceStep(
    id: 'areas-to-protect',
    chapter: 2,
    headline: Headline('Any areas to ', 'protect', '?'),
    subtitle: "We'll steer you away from plans that load these joints.",
    layout: ChoiceLayout.list,
    selection: ChoiceSelection.multi,
    autoAdvance: false,
    exclusiveOptionId: 'none',
    options: [
      ChoiceOption(
        id: 'none',
        imageKey: 'onboarding/goal-screen/none-about-you',
        label: 'None',
        glyph: '—',
      ),
      ChoiceOption(
        id: 'wrists',
        imageKey: 'onboarding/goal-screen/wrists',
        label: 'Wrists',
        glyph: 'W',
      ),
      ChoiceOption(
        id: 'shoulders',
        imageKey: 'onboarding/goal-screen/shoulders',
        label: 'Shoulders',
        glyph: 'S',
      ),
      ChoiceOption(
        id: 'lower-back',
        imageKey: 'onboarding/goal-screen/lower-back',
        label: 'Lower back',
        glyph: 'B',
      ),
      ChoiceOption(
        id: 'knees',
        imageKey: 'onboarding/goal-screen/knee',
        label: 'Knees',
        glyph: 'K',
      ),
      ChoiceOption(
        id: 'neck',
        imageKey: 'onboarding/goal-screen/neck',
        label: 'Neck',
        glyph: 'N',
      ),
    ],
  ),
];
