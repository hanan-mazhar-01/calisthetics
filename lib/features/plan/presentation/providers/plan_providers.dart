import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../paywall/presentation/providers/subscription_providers.dart';

import '../../../user/presentation/providers/user_providers.dart';
import '../../../plans/domain/plan_builder.dart';
import '../../../plans/data/plan_templates.dart';
import '../../../plans/domain/plan_template.dart';
import '../../../user/domain/active_plan.dart';
import '../../domain/plan_overview.dart';
import '../../domain/plan_timeline.dart';
import '../../../workout/domain/workout_state.dart';

/// Whether the user has Premium (free trial, monthly or yearly). Every
/// gate (extra plans, Discover videos) reads only this provider.
final isPremiumProvider = Provider<bool>(
  (ref) => ref.watch(subscriptionProvider).isPremium,
);

/// Plans a free user may have at once (Premium: all).
const freePlanLimit = 1;

/// Whether another plan may be added right now.
final canAddPlanProvider = Provider<bool>((ref) {
  return ref.watch(isPremiumProvider) ||
      ref.watch(ownedPlansProvider).length < freePlanLimit;
});

/// One row of the plan dropdown: an added plan with its progress in the
/// current 4-week block.
class PlanCardData {
  const PlanCardData({
    required this.plan,
    required this.template,
    required this.doneDays,
    required this.totalDays,
    required this.phaseDone,
    required this.isCurrent,
  });

  final ActivePlan plan;
  final PlanTemplate template;
  final int doneDays;
  final int totalDays;

  /// Per phase: whether every training day of it is done.
  final List<bool> phaseDone;
  final bool isCurrent;
}

final planCardsProvider = Provider<List<PlanCardData>>((ref) {
  final owned = ref.watch(ownedPlansProvider);
  final current = ref.watch(activePlanProvider);
  final history = ref.watch(historyProvider);
  final today = ref.watch(clockProvider)();
  return [
    for (final plan in owned)
      () {
        final template = planTemplates.firstWhere(
          (t) => t.id == plan.templateId,
        );
        final timeline = PlanTimeline.build(
          template: template,
          plan: plan,
          history: history,
          today: today,
        );
        return PlanCardData(
          plan: plan,
          template: template,
          doneDays: timeline.doneDays,
          totalDays: timeline.totalDays,
          phaseDone: [
            for (final ph in timeline.phases)
              ph.days.isNotEmpty && ph.doneCount == ph.days.length,
          ],
          isCurrent: plan.templateId == current?.templateId,
        );
      }(),
  ];
});

/// The Plan tab's derived state, or null when there is no active plan.
final planOverviewProvider = Provider<PlanOverview?>((ref) {
  final plan = ref.watch(activePlanProvider);
  final template = ref.watch(activeTemplateProvider);
  final week = ref.watch(currentWeekProvider);
  if (plan == null || template == null || week == null) return null;
  return PlanOverview.build(
    template: template,
    plan: plan,
    week: week,
    history: ref.watch(historyProvider),
    today: ref.watch(clockProvider)(),
  );
});

/// Spoken-cue level for workouts: 'off' | 'brief' | 'detailed'.
final voiceCuesProvider = Provider<String>((ref) {
  final v = ref.watch(settingsProvider)['voiceCues'];
  return v is String && const {'off', 'brief', 'detailed'}.contains(v)
      ? v
      : 'brief';
});

/// Rest between sets, in seconds (default 10).
final restSecondsProvider = Provider<int>((ref) {
  final v = ref.watch(settingsProvider)['restSeconds'];
  return v is int && v > 0 ? v : workoutRestSeconds;
});

/// The active plan's block as phases of training days (see [PlanTimeline]).
final planTimelineProvider = Provider<PlanTimeline?>((ref) {
  final plan = ref.watch(activePlanProvider);
  final template = ref.watch(activeTemplateProvider);
  if (plan == null || template == null) return null;
  return PlanTimeline.build(
    template: template,
    plan: plan,
    history: ref.watch(historyProvider),
    today: ref.watch(clockProvider)(),
  );
});

/// Plan week [week] (1-based) of the active plan, or null without a plan.
final builtWeekProvider = Provider.family<BuiltWeek?, int>((ref, week) {
  final plan = ref.watch(activePlanProvider);
  final template = ref.watch(activeTemplateProvider);
  if (plan == null || template == null) return null;
  return const PlanBuilder().buildWeek(
    template,
    plan.profile,
    week: week,
    stageIndex: plan.stageIndex,
    skipLeadingDays: week == 1 ? PlanTimeline.leadingSkip(plan) : 0,
  );
});
