import '../../onboarding/domain/skill_abilities.dart';
import '../data/plan_templates.dart';
import 'plan_template.dart';

enum PrimaryGoal { getStronger, toneBody, improveFitness, masterSkills }

enum TrainingSpace { home, gym, outdoor, minimal, both }

/// When the user prefers to train; drives the reminder time.
enum TrainingTime { morning, afternoon, evening, anytime }

enum ProtectedArea { wrists, shoulders, lowerBack, knees, neck }

/// What the plan engine needs to know about a user, distilled from their
/// onboarding answers. Pure data — [UserProfile.fromSelections] is the only
/// place that knows about onboarding option ids.
class UserProfile {
  const UserProfile({
    this.goal = PrimaryGoal.getStronger,
    this.extraGoals = const {},
    this.level = PlanLevel.beginner,
    this.space = TrainingSpace.home,
    this.protectedAreas = const {},
    this.sessionMinutes = 15,
    this.daysPerWeek = 3,
    this.equipmentOverride,
    this.timeOfDay = TrainingTime.anytime,
    this.plankSeconds,
    this.focusAreas = const {},
  });

  final PrimaryGoal goal;

  /// Ids from the "additional goals" step (e.g. `stronger-core`).
  final Set<String> extraGoals;
  final PlanLevel level;
  final TrainingSpace space;
  final Set<ProtectedArea> protectedAreas;
  final int sessionMinutes;
  final int daysPerWeek;

  /// Set once the user states their equipment explicitly; otherwise it is
  /// inferred from [space].
  final Set<PlanGear>? equipmentOverride;

  final TrainingTime timeOfDay;

  /// Seconds held in the onboarding plank test, when she took it.
  final int? plankSeconds;

  /// Ids from the "where should we focus" step (`core`, `legs`, ...).
  final Set<String> focusAreas;

  Set<PlanGear> get gear =>
      equipmentOverride ??
      switch (space) {
        TrainingSpace.home => {PlanGear.wall, PlanGear.chair},
        TrainingSpace.gym || TrainingSpace.both => PlanGear.values.toSet(),
        TrainingSpace.outdoor => {
          PlanGear.pullUpBar,
          PlanGear.parallelBars,
          PlanGear.wall,
        },
        TrainingSpace.minimal => {PlanGear.band, PlanGear.wall, PlanGear.chair},
      };

  UserProfile copyWith({
    Set<String>? focusAreas,
    PlanLevel? level,
    int? sessionMinutes,
    Set<ProtectedArea>? protectedAreas,
  }) => UserProfile(
    goal: goal,
    extraGoals: extraGoals,
    level: level ?? this.level,
    space: space,
    protectedAreas: protectedAreas ?? this.protectedAreas,
    sessionMinutes: sessionMinutes ?? this.sessionMinutes,
    daysPerWeek: daysPerWeek,
    equipmentOverride: equipmentOverride,
    timeOfDay: timeOfDay,
    plankSeconds: plankSeconds,
    focusAreas: focusAreas ?? this.focusAreas,
  );

  Map<String, dynamic> toJson() => {
    'goal': goal.name,
    'extraGoals': extraGoals.toList(),
    'level': level.name,
    'space': space.name,
    'protectedAreas': [for (final a in protectedAreas) a.name],
    'sessionMinutes': sessionMinutes,
    'daysPerWeek': daysPerWeek,
    if (equipmentOverride != null)
      'equipment': [for (final g in equipmentOverride!) g.name],
    'timeOfDay': timeOfDay.name,
    if (plankSeconds != null) 'plankSeconds': plankSeconds,
    'focusAreas': focusAreas.toList(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) {
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) {
      for (final v in values) {
        if (v.name == name) return v;
      }
      return fallback;
    }

    return UserProfile(
      goal: pick(PrimaryGoal.values, j['goal'], PrimaryGoal.getStronger),
      extraGoals: {...((j['extraGoals'] as List?) ?? const []).cast<String>()},
      level: pick(PlanLevel.values, j['level'], PlanLevel.beginner),
      space: pick(TrainingSpace.values, j['space'], TrainingSpace.home),
      protectedAreas: {
        for (final n
            in ((j['protectedAreas'] as List?) ?? const []).cast<String>())
          pick(ProtectedArea.values, n, ProtectedArea.wrists),
      },
      sessionMinutes: (j['sessionMinutes'] as int?) ?? 15,
      daysPerWeek: (j['daysPerWeek'] as int?) ?? 3,
      equipmentOverride: j['equipment'] == null
          ? null
          : {
              for (final n in (j['equipment'] as List).cast<String>())
                pick(PlanGear.values, n, PlanGear.wall),
            },
      timeOfDay: pick(
        TrainingTime.values,
        j['timeOfDay'],
        TrainingTime.anytime,
      ),
      plankSeconds: j['plankSeconds'] as int?,
      focusAreas: {...((j['focusAreas'] as List?) ?? const []).cast<String>()},
    );
  }

  /// Builds the profile from onboarding answers. [plankSeconds] is the measured
  /// plank hold (kept outside the selections).
  factory UserProfile.fromSelections(
    Map<String, Set<String>> s, {
    int? plankSeconds,
  }) {
    String? one(String step) =>
        (s[step] ?? const {}).isEmpty ? null : s[step]!.first;

    final goal = switch (one('main-goal')) {
      'fit-tone-my-body' => PrimaryGoal.toneBody,
      'improve-fitness' => PrimaryGoal.improveFitness,
      'master-calisthenics-skills' => PrimaryGoal.masterSkills,
      _ => PrimaryGoal.getStronger,
    };

    // The two self-assessments agree on a level; take the higher one so a
    // trained user isn't parked in the beginner stage.
    int rank(String? id) => switch (id) {
      'advanced' || 'strong-skilled' => 2,
      'intermediate' || 'fairly-strong' => 1,
      _ => 0,
    };
    final levelRank = [
      rank(one('training-experience')),
      rank(one('fitness-profile')),
    ].reduce((a, b) => a > b ? a : b);

    final space = switch (one('training-space')) {
      'gym' => TrainingSpace.gym,
      'both' => TrainingSpace.both,
      'outdoor' => TrainingSpace.outdoor,
      'minimal-equipment' => TrainingSpace.minimal,
      _ => TrainingSpace.home,
    };

    const areaIds = {
      'wrists': ProtectedArea.wrists,
      'shoulders': ProtectedArea.shoulders,
      'lower-back': ProtectedArea.lowerBack,
      'knees': ProtectedArea.knees,
      'neck': ProtectedArea.neck,
    };
    final protectedAreas = {
      for (final id in s['areas-to-protect'] ?? const <String>{})
        if (areaIds[id] != null) areaIds[id]!,
    };

    final minutes = switch (one('workout-duration')) {
      '10-min' => 10,
      '20-min' => 20,
      _ => 15,
    };

    // "None" in the equipment step means no extra gear; a wall is always
    // assumed. Unanswered keeps the inference from the training space.
    const gearIds = {
      'pull-up-bar': PlanGear.pullUpBar,
      'parallettes': PlanGear.parallelBars,
      'resistance-band': PlanGear.band,
      'chair-box': PlanGear.chair,
    };
    final equipmentAnswer = s['equipment'] ?? const <String>{};
    final equipment = equipmentAnswer.isEmpty
        ? null
        : {
            PlanGear.wall,
            for (final id in equipmentAnswer)
              if (gearIds[id] != null) gearIds[id]!,
          };

    final days = switch (one('days-per-week')) {
      'days-2' => 2,
      'days-4' => 4,
      'days-5' => 5,
      _ => 3,
    };

    final time = switch (one('time-of-day')) {
      'morning' => TrainingTime.morning,
      'afternoon' => TrainingTime.afternoon,
      'evening' => TrainingTime.evening,
      _ => TrainingTime.anytime,
    };

    // The ability answer belongs to the chosen plan's skill and decides the
    // starting stage: it replaces the self-assessed level for a skill plan
    // and can only raise it for a general plan.
    var level = PlanLevel.values[levelRank];
    final planId = one('plan-choice');
    PlanTemplate? chosen;
    for (final t in planTemplates) {
      if (t.id == planId) chosen = t;
    }
    final ability = chosen == null
        ? null
        : abilityById(chosen.skillId, one('skill-ability'));
    if (ability != null) {
      final fromAbility = PlanLevel.values[ability.stage];
      level = chosen!.skillId != null
          ? fromAbility
          : (fromAbility.index > level.index ? fromAbility : level);
    }

    return UserProfile(
      goal: goal,
      extraGoals: s['additional-goals'] ?? const {},
      level: level,
      space: space,
      protectedAreas: protectedAreas,
      sessionMinutes: minutes,
      daysPerWeek: days,
      equipmentOverride: equipment,
      timeOfDay: time,
      plankSeconds: plankSeconds,
      focusAreas: s['focus-areas'] ?? const {},
    );
  }
}
