import 'package:calisthenics/features/onboarding/domain/onboarding_plan_summary.dart';
import 'package:calisthenics/features/plans/domain/plan_builder.dart';
import 'package:flutter_test/flutter_test.dart';

OnboardingPlanSummary _summary(String planId, {Set<String> extra = const {}}) =>
    OnboardingPlanSummary.from({
      planChoiceKey: {planId},
      'training-experience': {'beginner'},
      'workout-duration': {'15-min'},
      if (extra.isNotEmpty) 'where-focus': extra,
    }, today: DateTime(2026, 10, 13))!;

void main() {
  test('phase targets are the seconds the player really runs', () {
    final s = _summary('foundation-full-body');
    for (final phase in s.phases) {
      expect(phase.targets, isNotEmpty);
      for (final t in phase.targets) {
        expect(t, matches(RegExp(r'^\d+s$')), reason: t);
        expect(
          int.parse(t.replaceAll('s', '')),
          greaterThanOrEqualTo(PlanBuilder.drillSeconds - 1),
        );
      }
    }
  });

  test('session minutes follow the chosen duration', () {
    final s = _summary('foundation-full-body');
    expect(s.minutesLabel, matches(RegExp(r'^(14|15|16)( min|–1[4-6] min)$')));
  });

  test('area shares come from the exercises actually chosen', () {
    final legs = _summary('legs-and-glutes');
    final shares = {
      for (final a in legs.allocations) a.label.split(' · ').first: a,
    };
    expect(shares['Legs & glutes']!.fraction, 1.0); // every session trains legs
    final core = _summary('core-control');
    final coreShares = {
      for (final a in core.allocations) a.label.split(' · ').first: a,
    };
    expect(coreShares['Core']!.fraction, 1.0);
    // Shares are real fractions of this plan's sessions, never invented.
    for (final a in [...legs.allocations, ...core.allocations]) {
      expect(a.fraction, inInclusiveRange(0, 1));
    }
  });

  test('the calendar shows exactly the training days of week 1', () {
    final s = _summary('foundation-full-body');
    expect(s.calendar.where((d) => d.isTraining).length, s.sessionsPerWeek);
  });
}
