import '../domain/onboarding_plan_summary.dart';
import '../domain/onboarding_step.dart';
import '../domain/skill_abilities.dart';

/// A handful of screens are written once as static data but should read
/// differently depending on what the user already told us: mainly the plan
/// she chose (and the real figures `PlanBuilder` produces for it) and her
/// plank result. Rather than threading Riverpod state through every data
/// file, this is the single place that patches a static [OnboardingStep]
/// into its personalized form right before render. Steps not listed here
/// pass through unchanged.
OnboardingStep applyDynamicContent(
  OnboardingStep step, {
  OnboardingPlanSummary? plan,
  int? plankSeconds,
}) {
  switch (step.id) {
    case 'skill-ability':
      final s = step as ChoiceStep;
      final skill = plan?.skill;
      return ChoiceStep(
        id: s.id,
        chapter: s.chapter,
        headline: skill == null
            ? const Headline('How would you ', 'describe', ' your strength?')
            : Headline('Your best ', skill.label, ' today?'),
        subtitle: skill == null
            ? 'Pick the closest match.'
            : 'This sets your starting point on the ${skill.label} ladder.',
        layout: s.layout,
        selection: s.selection,
        autoAdvance: s.autoAdvance,
        options: [
          for (final a in abilitiesFor(plan?.template.skillId)) a.toOption(),
        ],
      );

    case 'encouragement':
      if (plan == null) return step;
      final s = step as WinStep;
      return WinStep(
        id: s.id,
        chapter: s.chapter,
        headline: Headline('{name}, ', plan.outcome, ' is realistic.'),
        subtitle:
            'Your first ${plan.cycleDays} days are laid out. One session at a time.',
      );

    case 'personalized-projection':
      final s = step as CurveStep;
      final p = plankSeconds ?? 0;
      final goal = p < 30
          ? 30
          : p < 60
          ? 60
          : 90;
      final mid = (((p + goal) / 2) / 5).round() * 5;
      return CurveStep(
        id: s.id,
        chapter: s.chapter,
        headline: Headline('A ', '$goal-second', ' plank is a good target.'),
        xAxisLabels: s.xAxisLabels,
        points: [
          CurvePoint(
            xFraction: 0.10,
            yFraction: 0.84,
            label: p == 0 ? 'Start' : '${p}s',
          ),
          CurvePoint(xFraction: 0.50, yFraction: 0.54, label: '${mid}s'),
          CurvePoint(
            xFraction: 0.92,
            yFraction: 0.14,
            label: '${goal}s',
            emphasized: true,
          ),
        ],
        footer: p == 0 ? s.footer : 'You held $p seconds today. ${s.footer}',
      );

    case 'plan-creation':
      if (plan == null) return step;
      final s = step as LoadingStep;
      return LoadingStep(
        id: s.id,
        stages: s.stages,
        previewExercises: plan.previewExercises,
      );

    case 'personalized-result':
      if (plan == null) return step;
      final s = step as RevealStep;
      return RevealStep(
        id: s.id,
        ctaLabel: s.ctaLabel,
        stats: [
          PlanStat(
            value: '${plan.weeks.length}',
            label: 'Phases · ${plan.cycleDays} days',
          ),
          PlanStat(value: '${plan.sessionsPerWeek}', label: 'Sessions / week'),
          PlanStat(
            value: plan.minutesLabel.replaceAll(' min', ''),
            label: 'Minutes',
          ),
        ],
      );

    case 'plan-content':
      if (plan == null) return step;
      final s = step as PlanContentStep;
      final protected = plan.protectedLabels;
      return PlanContentStep(
        id: s.id,
        headline: s.headline,
        rows: [
          PlanRow(key: 'Plan', value: plan.template.name),
          PlanRow(key: 'Sessions', value: '${plan.sessionsPerWeek} × week'),
          PlanRow(key: 'Session length', value: plan.minutesLabel),
          PlanRow(key: 'Equipment', value: plan.equipmentLabel),
          if (plan.startingExercise != null)
            PlanRow(key: 'Starting point', value: plan.startingExercise!)
          else
            PlanRow(key: 'Starting stage', value: plan.stageName),
          PlanRow(
            key: 'Protected',
            value: protected.isEmpty ? 'None' : protected.join(', '),
          ),
        ],
        muscleAllocations: plan.allocations,
        calendar: plan.calendar,
        calendarNote: 'Your week. Highlighted days are training days.',
        ctaLabel: s.ctaLabel,
      );

    case 'plan-preview':
      if (plan == null) return step;
      final s = step as PlanPreviewStep;
      return PlanPreviewStep(
        id: s.id,
        headline: s.headline,
        phases: plan.phases,
        ctaLabel: s.ctaLabel,
      );

    default:
      return step;
  }
}
