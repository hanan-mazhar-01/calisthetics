import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/shared_preferences_provider.dart';
import '../../../onboarding/presentation/providers/onboarding_completed_provider.dart';
import '../../../onboarding/presentation/providers/onboarding_controller.dart';
import '../../../plans/domain/plan_builder.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../domain/achievement_evaluator.dart';
import '../../domain/profile_stats.dart';

final achievementsProvider = Provider<List<Achievement>>((ref) {
  final plan = ref.watch(activePlanProvider);
  // Weekdays the plan leaves free never break a streak (same rule as stats).
  final rest = plan == null
      ? const <int>{}
      : {0, 1, 2, 3, 4, 5, 6}.difference(
          PlanBuilder.trainingWeekdays(plan.profile.daysPerWeek).toSet(),
        );
  return const AchievementEvaluator().evaluate(
    history: ref.watch(historyProvider),
    stats: ref.watch(userStatsProvider),
    records: ref.watch(recordsProvider),
    plank: ref.watch(plankHistoryProvider),
    restWeekdays: rest,
  );
});

final personalRecordsProvider = Provider<PersonalRecords>(
  (ref) => PersonalRecords.from(
    ref.watch(historyProvider),
    ref.watch(userStatsProvider),
    ref.watch(recordsProvider),
  ),
);

final ladderProgressProvider = Provider<List<LadderProgress>>((ref) {
  final plan = ref.watch(activePlanProvider);
  return ladderProgress(
    history: ref.watch(historyProvider),
    template: ref.watch(activeTemplateProvider),
    stageIndex: plan?.stageIndex ?? 0,
  );
});

/// Newest first.
final recentHistoryProvider = Provider(
  (ref) =>
      [...ref.watch(historyProvider)]
        ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt)),
);

/// Account-level resets. Nothing here talks to a server: sign-in and cloud
/// sync are not integrated yet, so "delete account" only wipes this device.
class AccountActions {
  const AccountActions(this._ref);
  final Ref _ref;

  void _refreshAll() {
    _ref.invalidate(activePlanProvider);
    _ref.invalidate(historyProvider);
    _ref.invalidate(favoritesProvider);
    _ref.invalidate(recordsProvider);
    _ref.invalidate(settingsProvider);
    _ref.invalidate(onboardingControllerProvider);
    _ref.invalidate(onboardingCompletedProvider);
  }

  /// Wipes every local preference; the app returns to onboarding.
  Future<void> deleteLocalData() async {
    await _ref.read(userDataStoreProvider).clear();
    await _ref.read(sharedPreferencesProvider).clear();
    _refreshAll();
  }

  /// Drops the plan and the completed flag but keeps history, favorites and
  /// records, so a retake does not erase her progress.
  Future<void> retakeAssessment() async {
    await _ref.read(activePlanProvider.notifier).clear();
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setBool(onboardingCompletedKey, false);
    // Start the questions again from the first step.
    await prefs.setInt('onboarding_index', 0);
    _ref.invalidate(onboardingControllerProvider);
    _ref.invalidate(onboardingCompletedProvider);
  }
}

final accountActionsProvider = Provider<AccountActions>(AccountActions.new);
