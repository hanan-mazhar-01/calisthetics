import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plans/domain/plan_template.dart';
import '../../../plans/domain/user_profile.dart';
import '../../../onboarding/presentation/providers/onboarding_controller.dart';
import '../../../user/presentation/providers/user_providers.dart';

/// The preferences being edited on the Current Plan Settings screen. Edits
/// stay in this draft until "Update my current plan" applies them.
final planDraftProvider = NotifierProvider.autoDispose<PlanDraft, UserProfile>(
  PlanDraft.new,
);

class PlanDraft extends Notifier<UserProfile> {
  @override
  UserProfile build() =>
      ref.read(activePlanProvider)?.profile ?? const UserProfile();

  void setLevel(PlanLevel level) => state = state.copyWith(level: level);
  void setMinutes(int minutes) =>
      state = state.copyWith(sessionMinutes: minutes);
  void setFocus(Set<String> focus) => state = state.copyWith(focusAreas: focus);
  void setAvoid(Set<ProtectedArea> areas) =>
      state = state.copyWith(protectedAreas: areas);

  bool get changed {
    final current = ref.read(activePlanProvider)?.profile;
    if (current == null) return false;
    return current.level != state.level ||
        current.sessionMinutes != state.sessionMinutes ||
        !_same(current.focusAreas, state.focusAreas) ||
        !_same(current.protectedAreas, state.protectedAreas);
  }

  static bool _same<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);
}

/// The exact "training experience" option shown on the level slider. The plan
/// only knows three levels, but the slider has four options ("Beginner" and
/// "Some experience" are both [PlanLevel.beginner]), so the edit screen keeps
/// the chosen option here instead of deriving it from the profile.
final planDraftExperienceProvider =
    NotifierProvider.autoDispose<PlanDraftExperience, String>(
      PlanDraftExperience.new,
    );

class PlanDraftExperience extends Notifier<String> {
  @override
  String build() {
    final level = ref.read(planDraftProvider).level;
    // Start from what she answered in onboarding, if it still matches her level.
    final answered = ref
        .read(onboardingControllerProvider)
        .selections['training-experience']
        ?.firstOrNull;
    if (answered != null && levelFromOptionId(answered) == level) {
      return answered;
    }
    return levelOptionId(level);
  }

  void choose(String optionId) {
    state = optionId;
    ref.read(planDraftProvider.notifier).setLevel(levelFromOptionId(optionId));
  }
}

const focusLabels = {
  'shoulders': 'Shoulders',
  'arms': 'Arms',
  'core': 'Core',
  'back': 'Back',
  'glutes': 'Glutes',
  'legs': 'Legs',
};

String levelLabel(PlanLevel l) => switch (l) {
  PlanLevel.beginner => 'Beginner',
  PlanLevel.intermediate => 'Intermediate',
  PlanLevel.advanced => 'Advanced',
};

String areaLabel(ProtectedArea a) => switch (a) {
  ProtectedArea.wrists => 'Wrists',
  ProtectedArea.shoulders => 'Shoulders',
  ProtectedArea.lowerBack => 'Lower back',
  ProtectedArea.knees => 'Knees',
  ProtectedArea.neck => 'Neck',
};

String durationLabel(int minutes) =>
    minutes >= 30 ? '30+ mins' : '$minutes mins';

String summarize(Iterable<String> labels) =>
    labels.isEmpty ? 'None' : labels.join(', ');

// ── Mapping between the draft and the onboarding option ids ────────────────
// The edit screens reuse the onboarding cards, which speak in option ids.

String levelOptionId(PlanLevel l) => switch (l) {
  PlanLevel.beginner => 'beginner',
  PlanLevel.intermediate => 'intermediate',
  PlanLevel.advanced => 'advanced',
};

PlanLevel levelFromOptionId(String id) => switch (id) {
  'advanced' => PlanLevel.advanced,
  'intermediate' => PlanLevel.intermediate,
  _ => PlanLevel.beginner, // 'beginner' and 'some-experience'
};

String durationOptionId(int minutes) => switch (minutes) {
  <= 10 => '10-min',
  <= 15 => '15-min',
  _ => '20-min', // sessions run 10, 15 or 20 minutes
};

int durationFromOptionId(String id) => switch (id) {
  '10-min' => 10,
  '20-min' => 20,
  _ => 15,
};

const _areaOptionIds = {
  ProtectedArea.wrists: 'wrists',
  ProtectedArea.shoulders: 'shoulders',
  ProtectedArea.lowerBack: 'lower-back',
  ProtectedArea.knees: 'knees',
  ProtectedArea.neck: 'neck',
};

/// "None" when nothing is protected, so the exclusive card shows as selected.
Set<String> areaOptionIds(Set<ProtectedArea> areas) =>
    areas.isEmpty ? {'none'} : {for (final a in areas) _areaOptionIds[a]!};

Set<ProtectedArea> areasFromOptionIds(Set<String> ids) => {
  for (final e in _areaOptionIds.entries)
    if (ids.contains(e.value)) e.key,
};
