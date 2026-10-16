import '../domain/onboarding_step.dart';
import 'onboarding_chapter1_steps.dart';
import 'onboarding_chapter2_steps.dart';
import 'onboarding_chapter3_steps.dart';
import 'onboarding_chapter4_steps.dart';

/// Full ordered onboarding flow — all 4 chapters (screens 1-65 of the
/// reference). The main app shell and workout player (screens 66-77) are
/// a separate flow, reached once onboarding completes.
final List<OnboardingStep> onboardingSteps = [
  ...onboardingChapter1Steps,
  ...onboardingChapter2Steps,
  ...onboardingChapter3Steps,
  ...onboardingChapter4Steps,
];
