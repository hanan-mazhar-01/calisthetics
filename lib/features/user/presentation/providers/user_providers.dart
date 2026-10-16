import '../../../plan/domain/plan_timeline.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/shared_preferences_provider.dart';
import '../../../plans/data/plan_templates.dart';
import '../../../plans/domain/plan_builder.dart';
import '../../../plans/domain/plan_template.dart';
import '../../../plans/domain/user_profile.dart';
import '../../data/user_data_store.dart';
import '../../domain/active_plan.dart';
import '../../domain/completed_session.dart';
import '../../domain/partial_effort.dart';
import '../../domain/plank_attempt.dart';
import '../../domain/user_stats.dart';

final userDataStoreProvider = Provider<UserDataStore>(
  (ref) => UserDataStore(ref.watch(sharedPreferencesProvider)),
);

/// "Today" for the whole app; override in tests to pin the date.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

// ── Active plan ─────────────────────────────────────────────────────

/// Every plan the user has added (one per template), oldest first.
final ownedPlansProvider =
    NotifierProvider<OwnedPlansNotifier, List<ActivePlan>>(
      OwnedPlansNotifier.new,
    );

class OwnedPlansNotifier extends Notifier<List<ActivePlan>> {
  @override
  List<ActivePlan> build() {
    final plans = ref.read(userDataStoreProvider).readPlans();
    final advanced = [for (final p in plans) _advanceStages(p)];
    if (advanced.indexed.any((e) => !identical(e.$2, plans[e.$1]))) {
      ref.read(userDataStoreProvider).writePlans(advanced);
    }
    return advanced;
  }

  Future<void> upsert(ActivePlan plan) async {
    final i = state.indexWhere((p) => p.templateId == plan.templateId);
    final next = [...state];
    if (i < 0) {
      next.add(plan);
    } else {
      next[i] = plan;
    }
    state = next;
    await ref.read(userDataStoreProvider).writePlans(state);
  }

  Future<void> remove(String templateId) async {
    state = [
      for (final p in state)
        if (p.templateId != templateId) p,
    ];
    await ref.read(userDataStoreProvider).writePlans(state);
  }

  Future<void> clear() async {
    state = const [];
    await ref.read(userDataStoreProvider).writePlans(const []);
  }

  /// After each finished 4-week cycle, move up a stage if at least 75% of
  /// that cycle's planned sessions were completed.
  ActivePlan _advanceStages(ActivePlan plan) {
    final template = planTemplates.firstWhere(
      (t) => t.id == plan.templateId,
      orElse: () => planTemplates.first,
    );
    final today = ref.read(clockProvider)();
    final finishedCycles = (plan.weekNumberOn(today) - 1) ~/ 4;
    if (finishedCycles <= plan.cyclesApplied) return plan;

    const builder = PlanBuilder();
    final history = ref.read(userDataStoreProvider).readHistory();
    var updated = plan;
    for (var cycle = plan.cyclesApplied; cycle < finishedCycles; cycle++) {
      final from = plan.startDate.add(Duration(days: cycle * 28));
      final to = from.add(const Duration(days: 28));
      final done = history
          .where(
            (s) =>
                plan.counts(s) &&
                !s.finishedAt.isBefore(from) &&
                s.finishedAt.isBefore(to),
          )
          .length;
      final planned = plan.profile.daysPerWeek * 4;
      updated = updated.copyWith(
        stageIndex: builder.nextStage(
          template,
          updated.stageIndex,
          sessionsDone: done,
          sessionsPlanned: planned,
        ),
        cyclesApplied: cycle + 1,
      );
    }
    return updated;
  }
}

/// Template id of the plan being followed right now.
final currentPlanIdProvider = NotifierProvider<CurrentPlanIdNotifier, String?>(
  CurrentPlanIdNotifier.new,
);

class CurrentPlanIdNotifier extends Notifier<String?> {
  @override
  String? build() => ref.read(userDataStoreProvider).readCurrentPlanId();

  Future<void> set(String? id) async {
    state = id;
    await ref.read(userDataStoreProvider).writeCurrentPlanId(id);
  }
}

/// The plan the whole app follows (Plan tab, Progress, Discover): the chosen
/// current plan among [ownedPlansProvider], or null when none was added.
final activePlanProvider = NotifierProvider<ActivePlanNotifier, ActivePlan?>(
  ActivePlanNotifier.new,
);

class ActivePlanNotifier extends Notifier<ActivePlan?> {
  @override
  ActivePlan? build() {
    final plans = ref.watch(ownedPlansProvider);
    final id = ref.watch(currentPlanIdProvider);
    for (final p in plans) {
      if (p.templateId == id) return p;
    }
    return plans.firstOrNull;
  }

  /// Starts [template] today and makes it the current plan. Other plans the
  /// user added stay. The starting stage follows the user's level.
  Future<void> start(PlanTemplate template, UserProfile profile) async {
    final now = ref.read(clockProvider)();
    final plan = ActivePlan(
      templateId: template.id,
      startDate: DateTime(now.year, now.month, now.day),
      progressFrom: now,
      profile: profile,
      stageIndex: const PlanBuilder().startingStage(template, profile),
    );
    await ref.read(ownedPlansProvider.notifier).upsert(plan);
    await ref.read(currentPlanIdProvider.notifier).set(template.id);
  }

  /// Makes an already-added plan the current one.
  Future<void> switchTo(String templateId) async {
    if (!ref.read(ownedPlansProvider).any((p) => p.templateId == templateId)) {
      return;
    }
    await ref.read(currentPlanIdProvider.notifier).set(templateId);
  }

  /// Drops one added plan (its workout history is kept). If it was the
  /// current plan, the first remaining plan becomes current.
  Future<void> remove(String templateId) async {
    await ref.read(ownedPlansProvider.notifier).remove(templateId);
    if (ref.read(currentPlanIdProvider) == templateId) {
      final left = ref.read(ownedPlansProvider);
      await ref
          .read(currentPlanIdProvider.notifier)
          .set(left.firstOrNull?.templateId);
    }
  }

  /// Applies edited preferences (focus, level, duration, avoided areas) to
  /// the current plan. Progress dates stay; the stage follows the level when
  /// the level changed.
  Future<void> updateProfile(UserProfile profile) async {
    final plan = state;
    if (plan == null) return;
    final template = planTemplates.firstWhere((t) => t.id == plan.templateId);
    final levelChanged = profile.level != plan.profile.level;
    await ref
        .read(ownedPlansProvider.notifier)
        .upsert(
          plan.copyWith(
            profile: profile,
            stageIndex: levelChanged
                ? const PlanBuilder().startingStage(template, profile)
                : plan.stageIndex,
          ),
        );
  }

  /// Restarts the current plan from today at its first stage.
  Future<void> restart() async {
    final plan = state;
    if (plan == null) return;
    await start(
      planTemplates.firstWhere((t) => t.id == plan.templateId),
      plan.profile,
    );
    // Half-finished days from the old run no longer apply.
    await ref
        .read(partialProgressProvider.notifier)
        .clearWhere((key) => key.startsWith('${plan.templateId}|'));
  }

  /// Removes every plan (used when the account data is wiped).
  Future<void> clear() async {
    await ref.read(ownedPlansProvider.notifier).clear();
    await ref.read(currentPlanIdProvider.notifier).set(null);
  }
}

/// The template of the active plan, or null.
final activeTemplateProvider = Provider<PlanTemplate?>((ref) {
  final plan = ref.watch(activePlanProvider);
  if (plan == null) return null;
  for (final t in planTemplates) {
    if (t.id == plan.templateId) return t;
  }
  return null;
});

/// This week's schedule for the active plan, or null when there is no plan.
final currentWeekProvider = Provider<BuiltWeek?>((ref) {
  final plan = ref.watch(activePlanProvider);
  final template = ref.watch(activeTemplateProvider);
  if (plan == null || template == null) return null;
  final today = ref.watch(clockProvider)();
  return const PlanBuilder().buildWeek(
    template,
    plan.profile,
    week: plan.weekNumberOn(today),
    stageIndex: plan.stageIndex,
    skipLeadingDays: plan.weekNumberOn(today) == 1
        ? PlanTimeline.leadingSkip(plan)
        : 0,
  );
});

// ── History & stats ─────────────────────────────────────────────────

final historyProvider =
    NotifierProvider<HistoryNotifier, List<CompletedSession>>(
      HistoryNotifier.new,
    );

class HistoryNotifier extends Notifier<List<CompletedSession>> {
  @override
  List<CompletedSession> build() =>
      ref.read(userDataStoreProvider).readHistory();

  Future<void> add(CompletedSession session) async {
    state = [...state, session];
    await ref.read(userDataStoreProvider).writeHistory(state);
  }

  /// Removes one entry (used to delete an activity she logged by hand).
  Future<void> remove(CompletedSession session) async {
    final i = state.indexWhere(
      (s) =>
          s.finishedAt == session.finishedAt &&
          s.sessionName == session.sessionName &&
          s.templateId == session.templateId,
    );
    if (i < 0) return;
    state = [...state]..removeAt(i);
    await ref.read(userDataStoreProvider).writeHistory(state);
  }
}

final userStatsProvider = Provider<UserStats>((ref) {
  final plan = ref.watch(activePlanProvider);
  // Weekdays the plan leaves free: they never break the streak.
  final rest = plan == null
      ? const <int>{}
      : {0, 1, 2, 3, 4, 5, 6}.difference(
          PlanBuilder.trainingWeekdays(plan.profile.daysPerWeek).toSet(),
        );
  return UserStats.from(
    ref.watch(historyProvider),
    today: ref.watch(clockProvider)(),
    restWeekdays: rest,
  );
});

// ── Favorites, records, settings ────────────────────────────────────

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<int>>(
  FavoritesNotifier.new,
);

class FavoritesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => ref.read(userDataStoreProvider).readFavorites();

  Future<void> toggle(int exerciseNumber) async {
    final next = {...state};
    if (!next.add(exerciseNumber)) next.remove(exerciseNumber);
    state = next;
    await ref.read(userDataStoreProvider).writeFavorites(next);
  }
}

/// Personal records by key (`plankSeconds`, …). Higher is better.
final recordsProvider = NotifierProvider<RecordsNotifier, Map<String, int>>(
  RecordsNotifier.new,
);

class RecordsNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => ref.read(userDataStoreProvider).readRecords();

  /// Stores [value] only if it beats the current record. Plank holds are also
  /// kept in the plank history (every attempt, not just records).
  Future<void> submit(String key, int value) async {
    // History first, without awaiting: it must not delay the record update
    // (callers read the record right after calling this).
    if (key == 'plankSeconds' && value > 0) {
      final history = ref.read(plankHistoryProvider.notifier).add(value);
      unawaited(history);
    }
    if (value <= (state[key] ?? 0)) return;
    state = {...state, key: value};
    await ref.read(userDataStoreProvider).writeRecords(state);
  }
}

/// Every timed plank hold, oldest first.
final plankHistoryProvider =
    NotifierProvider<PlankHistoryNotifier, List<PlankAttempt>>(
      PlankHistoryNotifier.new,
    );

/// Percent done in workouts she left early without marking them complete,
/// keyed by [dayProgressKey]. Shown on the plan; it never counts as a
/// finished day.
final partialProgressProvider =
    NotifierProvider<PartialProgressNotifier, Map<String, int>>(
      PartialProgressNotifier.new,
    );

class PartialProgressNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() =>
      ref.read(userDataStoreProvider).readPartialProgress();

  Future<void> set(String key, int percent) async {
    state = {...state, key: percent.clamp(0, 99)};
    await ref.read(userDataStoreProvider).writePartialProgress(state);
  }

  Future<void> clearWhere(bool Function(String key) test) async {
    final next = {
      for (final e in state.entries)
        if (!test(e.key)) e.key: e.value,
    };
    if (next.length == state.length) return;
    state = next;
    await ref.read(userDataStoreProvider).writePartialProgress(state);
  }

  Future<void> clear(String key) async {
    if (!state.containsKey(key)) return;
    state = {...state}..remove(key);
    await ref.read(userDataStoreProvider).writePartialProgress(state);
  }
}

/// Work from workouts quit early without the day being marked complete.
final partialLogProvider =
    NotifierProvider<PartialLogNotifier, List<PartialEffort>>(
      PartialLogNotifier.new,
    );

class PartialLogNotifier extends Notifier<List<PartialEffort>> {
  @override
  List<PartialEffort> build() =>
      ref.read(userDataStoreProvider).readPartialLog();

  Future<void> add(PartialEffort effort) async {
    state = [...state, effort];
    await ref.read(userDataStoreProvider).writePartialLog(state);
  }
}

/// Stable id of one planned day: the plan template plus the calendar date the
/// day falls on. Partial progress is stored under it.
String dayProgressKey(String templateId, DateTime date) =>
    '$templateId|${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class PlankHistoryNotifier extends Notifier<List<PlankAttempt>> {
  @override
  List<PlankAttempt> build() =>
      ref.read(userDataStoreProvider).readPlankHistory();

  Future<void> add(int seconds) async {
    state = [
      ...state,
      PlankAttempt(at: ref.read(clockProvider)(), seconds: seconds),
    ];
    await ref.read(userDataStoreProvider).writePlankHistory(state);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, Map<String, dynamic>>(
      SettingsNotifier.new,
    );

class SettingsNotifier extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() =>
      ref.read(userDataStoreProvider).readSettings();

  Future<void> set(String key, Object? value) async {
    state = {...state, key: value};
    await ref.read(userDataStoreProvider).writeSettings(state);
  }
}
