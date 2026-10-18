import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/shared_preferences_provider.dart';
import '../../../../shared/models/calisthenics_skill.dart';
import '../../../plans/data/plan_templates.dart';
import '../../../plans/domain/plan_template.dart';
import '../../../plans/domain/user_profile.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../data/onboarding_flow.dart';
import '../../domain/onboarding_plan_summary.dart';
import '../../domain/onboarding_step.dart';
import 'onboarding_completed_provider.dart';
import 'onboarding_state.dart';

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

/// Owns onboarding progress: which step the user is on and what they've
/// selected so far. Persists both to disk so the flow resumes where the
/// user left off (never loses onboarding progress on app restart).
class OnboardingController extends Notifier<OnboardingState> {
  static const _indexKey = 'onboarding_index';
  static const _selectionsKey = 'onboarding_selections';
  static const _nameKey = 'onboarding_name';
  static const _schemaKey = 'onboarding_schema_version';
  static const _plankKey = 'onboarding_plank_seconds';
  static const _schemaVersion = 3;

  /// Option lists as they stood before ids were reshuffled in schema 3; the
  /// schema-1 index migration reads positions against these.
  static const _legacyOptionIds = {
    'training-space': ['home', 'gym', 'outdoor', 'minimal-equipment'],
    'fitness-profile': [
      'just-starting',
      'building-a-base',
      'fairly-strong',
      'strong-skilled',
    ],
    'daily-activity': [
      'mostly-sitting',
      'a-mix',
      'on-my-feet',
      'always-moving',
    ],
  };

  bool _finishing = false;

  @override
  OnboardingState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    _migrate(prefs);
    final savedIndex = prefs.getInt(_indexKey) ?? 0;
    final selections = <String, Set<String>>{};
    final savedJson = prefs.getString(_selectionsKey);
    if (savedJson != null) {
      final decoded = jsonDecode(savedJson) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        selections[entry.key] = (entry.value as List).cast<String>().toSet();
      }
    }
    return OnboardingState(
      index: savedIndex.clamp(0, onboardingSteps.length - 1),
      selections: selections,
      name: prefs.getString(_nameKey) ?? '',
      plankSeconds: prefs.getInt(_plankKey),
    );
  }

  OnboardingStep get currentStep => onboardingSteps[state.index];
  bool get isFirstStep => state.index == 0;
  bool get isLastStep => state.index == onboardingSteps.length - 1;

  /// The step after this one is the sign-in step (skipped when signed in).
  bool get nextStepIsAccount =>
      !isLastStep && onboardingSteps[state.index + 1] is AccountStep;

  /// 1-based position of the current step within its chapter, and how many
  /// steps that chapter has in total — drives the segmented progress bar.
  ({int step, int total}) get chapterProgress {
    final chapter = currentStep.chapter;
    if (chapter == null) return (step: 0, total: 0);
    final indices = [
      for (var i = 0; i < onboardingSteps.length; i++)
        if (onboardingSteps[i].chapter == chapter) i,
    ];
    return (step: indices.indexOf(state.index) + 1, total: indices.length);
  }

  void next() {
    if (isLastStep) return;
    var target = state.index + 1;
    if (target < onboardingSteps.length && _isSkipped(target)) target++;
    state = state.copyWith(index: target);
    _persistIndex();
  }

  /// The plan the user picked, or the recommended one if none is saved yet.
  PlanTemplate _chosenTemplate() {
    final chosenId = selectionsFor(planChoiceKey).firstOrNull;
    return planTemplates.firstWhere(
      (t) => t.id == chosenId,
      orElse: () => heroRecommendation(
        recommendationsFor(state.selections, plankSeconds: state.plankSeconds),
      ).template,
    );
  }

  /// The "where are you today" question only makes sense for a skill plan
  /// (it picks the starting rung). Other plans already know the level from
  /// the experience question and the plank test, so the step is skipped.
  bool _isSkipped(int index) =>
      onboardingSteps[index].id == 'skill-ability' &&
      _chosenTemplate().skillId == null;

  /// Marks onboarding as done; the router redirect then keeps the user in
  /// the main app on every later launch.
  Future<void> finish() =>
      ref.read(onboardingCompletedProvider.notifier).complete();

  /// The last onboarding action: starts the chosen plan (falling back to the
  /// recommended one) with a profile built from every answer, keeps the
  /// preferred time of day for the reminder, then marks onboarding done.
  Future<void> startPlanAndFinish() async {
    if (_finishing) return;
    _finishing = true;
    final selections = state.selections;
    final chosenId = selectionsFor(planChoiceKey).firstOrNull;
    final template = planTemplates.firstWhere(
      (t) => t.id == chosenId,
      orElse: () => heroRecommendation(
        recommendationsFor(selections, plankSeconds: state.plankSeconds),
      ).template,
    );
    if (chosenId != template.id) choosePlan(template.id);
    final profile = UserProfile.fromSelections(
      state.selections,
      plankSeconds: state.plankSeconds,
    );
    await ref.read(activePlanProvider.notifier).start(template, profile);
    await ref
        .read(settingsProvider.notifier)
        .set('timeOfDay', profile.timeOfDay.name);
    await finish();
    _finishing = false;
  }

  void back() {
    if (isFirstStep) return;
    var target = state.index - 1;
    if (target > 0 && _isSkipped(target)) target--;
    state = state.copyWith(index: target);
    _persistIndex();
  }

  void toggleOption(String stepId, String optionId, {required bool multi}) {
    final current = Set<String>.of(state.selections[stepId] ?? const {});
    if (multi) {
      final exclusive = _exclusiveOptionFor(stepId);
      if (exclusive != null && optionId == exclusive) {
        // "None" replaces everything; tapping it again clears it.
        final wasOn = current.contains(exclusive);
        current.clear();
        if (!wasOn) current.add(exclusive);
      } else {
        if (exclusive != null) current.remove(exclusive);
        if (!current.add(optionId)) current.remove(optionId);
      }
    } else {
      current
        ..clear()
        ..add(optionId);
    }
    final updated = Map<String, Set<String>>.of(state.selections)
      ..[stepId] = current;
    state = state.copyWith(selections: updated);
    _persistSelections();
  }

  String? _exclusiveOptionFor(String stepId) {
    for (final step in onboardingSteps) {
      if (step.id == stepId && step is ChoiceStep) {
        return step.exclusiveOptionId;
      }
    }
    return null;
  }

  /// Records the chosen plan. A different plan has a different ability
  /// question, so the previous ability answer is dropped.
  void choosePlan(String templateId) {
    final previous = selectionsFor(planChoiceKey).firstOrNull;
    final updated = Map<String, Set<String>>.of(state.selections)
      ..[planChoiceKey] = {templateId};
    if (previous != templateId) updated.remove(abilityKey);
    state = state.copyWith(selections: updated);
    _persistSelections();
  }

  /// Stores the plank-test result in onboarding state and as the first
  /// personal record.
  void setPlankSeconds(int seconds) {
    state = state.copyWith(plankSeconds: seconds);
    ref.read(sharedPreferencesProvider).setInt(_plankKey, seconds);
    ref.read(recordsProvider.notifier).submit('plankSeconds', seconds);
  }

  Set<String> selectionsFor(String stepId) =>
      state.selections[stepId] ?? const {};

  void setName(String value) {
    state = state.copyWith(name: value);
    ref.read(sharedPreferencesProvider).setString(_nameKey, value);
  }

  /// Substitutes `{name}` in copy with the captured first name (defaults to
  /// "you", matching the source design's fallback).
  String interpolateName(String text) {
    final name = state.name.trim();
    return text.replaceAll('{name}', name.isEmpty ? 'you' : name);
  }

  void _migrate(SharedPreferences prefs) {
    final version = prefs.getInt(_schemaKey) ?? 1;
    if (version >= _schemaVersion) return;
    if (version < 2) _migrateIndexSelections(prefs);
    if (version < 3) _migrateToSchema3(prefs);
    prefs.setInt(_schemaKey, _schemaVersion);
  }

  /// Schema 3 reshaped the flow: "Where will you train?" became Home / Gym /
  /// Both, the two self-assessments merged into the experience step, the
  /// "typical day" step went away, and a few ability ids were corrected.
  /// Step positions changed too, so the saved position restarts at the
  /// first step; answers are kept and show pre-selected.
  void _migrateToSchema3(SharedPreferences prefs) {
    final savedJson = prefs.getString(_selectionsKey);
    if (savedJson != null) {
      final decoded = jsonDecode(savedJson) as Map<String, dynamic>;
      final sel = <String, List<String>>{
        for (final e in decoded.entries)
          e.key: (e.value as List).cast<String>(),
      };
      const space = {'outdoor': 'both', 'minimal-equipment': 'home'};
      sel['training-space'] = [
        for (final id in sel['training-space'] ?? const <String>[])
          space[id] ?? id,
      ];
      const experience = {
        'just-starting': 'beginner',
        'building-a-base': 'some-experience',
        'fairly-strong': 'intermediate',
        'strong-skilled': 'advanced',
      };
      final legacyStrength = sel.remove('fitness-profile');
      if ((sel['training-experience'] ?? const []).isEmpty &&
          legacyStrength != null) {
        sel['training-experience'] = [
          for (final id in legacyStrength)
            if (experience[id] != null) experience[id]!,
        ];
      }
      const ability = {
        'bench-dips': 'dip-support-hold',
        'negative-dip': 'partial-range-dip',
        'full-dip': 'strict-dip',
        'kipping-toes-to-bar': 'toes-to-bar-negative',
      };
      sel['skill-ability'] = [
        for (final id in sel['skill-ability'] ?? const <String>[])
          ability[id] ?? id,
      ];
      sel
        ..remove('daily-activity')
        ..removeWhere((_, v) => v.isEmpty);
      prefs.setString(_selectionsKey, jsonEncode(sel));
    }
    prefs.setInt(_indexKey, 0);
  }

  /// One-time upgrade of answers saved before options had stable ids: those
  /// were stored as list positions. Positions are translated through the
  /// option lists as they stood when the data was written; the removed
  /// `dream-skill` answer only decides which skill's ability list applies.
  void _migrateIndexSelections(SharedPreferences prefs) {
    final savedJson = prefs.getString(_selectionsKey);
    if (savedJson != null) {
      final decoded = jsonDecode(savedJson) as Map<String, dynamic>;
      final dreamIndices =
          (decoded['dream-skill'] as List?)?.cast<int>() ?? const <int>[];
      final skillIndex = dreamIndices.isEmpty ? 0 : dreamIndices.first;
      final skill =
          calisthenicsSkills[skillIndex.clamp(
            0,
            calisthenicsSkills.length - 1,
          )];
      final migrated = <String, List<String>>{};
      for (final entry in decoded.entries) {
        final ids = _optionIdsFor(entry.key, skill);
        if (ids == null) continue;
        final indices = (entry.value as List).cast<int>();
        migrated[entry.key] = [
          for (final i in indices)
            if (i >= 0 && i < ids.length) ids[i],
        ];
      }
      prefs.setString(_selectionsKey, jsonEncode(migrated));
    }
  }

  List<String>? _optionIdsFor(String stepId, CalisthenicsSkill skill) {
    if (stepId == 'skill-ability') {
      return [for (final o in skill.abilityLevels) o.id];
    }
    final legacy = _legacyOptionIds[stepId];
    if (legacy != null) return legacy;
    for (final step in onboardingSteps) {
      if (step.id != stepId) continue;
      if (step is ChoiceStep) return [for (final o in step.options) o.id];
      if (step is FocusStep) return [for (final a in step.areas) a.id];
    }
    return null;
  }

  void _persistIndex() {
    ref.read(sharedPreferencesProvider).setInt(_indexKey, state.index);
  }

  void _persistSelections() {
    final encoded = state.selections.map(
      (key, value) => MapEntry(key, value.toList()),
    );
    ref
        .read(sharedPreferencesProvider)
        .setString(_selectionsKey, jsonEncode(encoded));
  }
}
