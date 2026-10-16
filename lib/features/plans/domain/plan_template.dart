import 'user_profile.dart';

/// Broad training level a stage is written for.
enum PlanLevel { beginner, intermediate, advanced }

/// What a plan is mainly for; the recommender matches this to the user's goal.
enum PlanFocus { fullBody, core, legsGlutes, conditioning, mobility, skill }

/// Gear a plan needs beyond a mat. Matched against where the user trains.
enum PlanGear { pullUpBar, parallelBars, wall, band, chair }

/// One exercise inside a session: a catalog exercise number plus its target.
class PlanItem {
  const PlanItem.reps(
    this.exerciseNumber,
    this.sets,
    int this.reps, {
    this.perSide = false,
  }) : holdSeconds = null;
  const PlanItem.hold(
    this.exerciseNumber,
    this.sets,
    int this.holdSeconds, {
    this.perSide = false,
  }) : reps = null;

  final int exerciseNumber;
  final int sets;
  final int? reps;
  final int? holdSeconds;
  final bool perSide;

  bool get isHold => holdSeconds != null;
}

/// A named workout day blueprint (warm-up and cool-down are added by [PlanBuilder]).
class PlanSession {
  const PlanSession({
    required this.name,
    required this.focus,
    required this.items,
  });

  final String name;

  /// Drives which warm-up and cool-down drills are attached.
  final PlanSessionFocus focus;
  final List<PlanItem> items;
}

enum PlanSessionFocus { upper, lower, core, full }

/// A block of sessions at one level. Skill plans have several stages
/// (foundation → build → master); other plans have one.
class PlanStage {
  const PlanStage({
    required this.name,
    required this.level,
    required this.sessions,
  });

  final String name;
  final PlanLevel level;
  final List<PlanSession> sessions;
}

/// A reusable program the app can recommend. Pure data: no user state.
class PlanTemplate {
  const PlanTemplate({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.focus,
    required this.gear,
    required this.stages,
    this.skillId,
    this.strainsWrists = false,
    this.strainsShoulders = false,
    this.strainsKnees = false,
    this.strainsLowerBack = false,
    this.invertsNeck = false,
  });

  final String id;
  final String name;
  final String tagline;
  final String description;
  final PlanFocus focus;
  final Set<PlanGear> gear;
  final List<PlanStage> stages;

  /// Catalog skill id (see `calisthenicsSkills`) when [focus] is [PlanFocus.skill].
  final String? skillId;

  /// Joints the plan loads heavily. The recommender avoids these when the
  /// user flagged the area — it adjusts training, it is not medical advice.
  final bool strainsWrists;
  final bool strainsShoulders;
  final bool strainsKnees;
  final bool strainsLowerBack;
  final bool invertsNeck;

  /// Which of [areas] this plan loads heavily.
  Set<ProtectedArea> conflictsWith(Set<ProtectedArea> areas) => {
    if (strainsWrists && areas.contains(ProtectedArea.wrists))
      ProtectedArea.wrists,
    if (strainsShoulders && areas.contains(ProtectedArea.shoulders))
      ProtectedArea.shoulders,
    if (strainsKnees && areas.contains(ProtectedArea.knees))
      ProtectedArea.knees,
    if (strainsLowerBack && areas.contains(ProtectedArea.lowerBack))
      ProtectedArea.lowerBack,
    if (invertsNeck && areas.contains(ProtectedArea.neck)) ProtectedArea.neck,
  };

  /// The exercise whose picture stands for the plan: the first exercise of
  /// its first session.
  int get coverExerciseNumber =>
      stages.first.sessions.first.items.first.exerciseNumber;

  Iterable<int> get exerciseNumbers sync* {
    for (final stage in stages) {
      for (final session in stage.sessions) {
        for (final item in session.items) {
          yield item.exerciseNumber;
        }
      }
    }
  }
}
