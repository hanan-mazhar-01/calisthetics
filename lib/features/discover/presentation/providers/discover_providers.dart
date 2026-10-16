import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../exercises/domain/exercise.dart';
import '../../../plan/presentation/providers/plan_providers.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../domain/discover_logic.dart';
import '../../domain/exercise_access_policy.dart';

/// Whether the user has premium: the same single source the paywall uses,
/// so Discover and the plan flow can never disagree.
final premiumAccessProvider = Provider<bool>(
  (ref) => ref.watch(isPremiumProvider),
);

/// Catalog numbers used by the active plan (all stages).
final planExerciseNumbersProvider = Provider<Set<int>>((ref) {
  final template = ref.watch(activeTemplateProvider);
  return template == null ? const {} : template.exerciseNumbers.toSet();
});

final exerciseAccessPolicyProvider = Provider<ExerciseAccessPolicy>(
  (ref) => ExerciseAccessPolicy(
    isPremium: ref.watch(premiumAccessProvider),
    planExerciseNumbers: ref.watch(planExerciseNumbersProvider),
  ),
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class DiscoverFiltersNotifier extends Notifier<DiscoverFilters> {
  @override
  DiscoverFilters build() => const DiscoverFilters();

  void toggleEquipment(EquipmentTag tag) {
    final next = {...state.equipment};
    if (!next.add(tag)) next.remove(tag);
    state = state.copyWith(equipment: next);
  }

  void toggleLevel(ExerciseLevel level) {
    final next = {...state.levels};
    if (!next.add(level)) next.remove(level);
    state = state.copyWith(levels: next);
  }

  void toggleFavorites() =>
      state = state.copyWith(favoritesOnly: !state.favoritesOnly);

  void clear() => state = const DiscoverFilters();
}

final discoverFiltersProvider =
    NotifierProvider<DiscoverFiltersNotifier, DiscoverFilters>(
      DiscoverFiltersNotifier.new,
    );

/// True when Discover should show a flat result list instead of browsing.
final discoverSearchingProvider = Provider<bool>(
  (ref) =>
      ref.watch(searchQueryProvider).trim().isNotEmpty ||
      ref.watch(discoverFiltersProvider).isActive,
);

final discoverResultsProvider = Provider<List<Exercise>>((ref) {
  return searchExercises(
    ref.watch(searchQueryProvider),
    filters: ref.watch(discoverFiltersProvider),
    favorites: ref.watch(favoritesProvider),
  );
});

/// Current rung of a skill ladder for this user.
final currentRungProvider = Provider.family<Exercise, String>((ref, skillId) {
  return currentRungFor(
    skillId,
    plan: ref.watch(activePlanProvider),
    template: ref.watch(activeTemplateProvider),
    history: ref.watch(historyProvider),
  );
});

/// Skill id of the active plan, when it is a skill plan; else null.
final continueLadderSkillProvider = Provider<String?>(
  (ref) => ref.watch(activeTemplateProvider)?.skillId,
);
