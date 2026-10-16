import '../../plans/domain/plan_template.dart';

/// Conversation starters shaped by the active plan. General training
/// questions only — never medical ones.
List<String> coachStarters(PlanTemplate? plan) {
  if (plan == null) {
    return const [
      'How do I start calisthenics as a beginner?',
      'How often should I train each week?',
      'What should I do in a warm-up?',
    ];
  }
  return [
    'How do I get the most out of ${plan.name}?',
    'What should my first week feel like?',
    if (plan.focus == PlanFocus.skill)
      'How do I know when I\'m ready for the next step?'
    else
      'How do I make my sessions a little harder over time?',
    'How should I warm up before this plan?',
  ];
}
