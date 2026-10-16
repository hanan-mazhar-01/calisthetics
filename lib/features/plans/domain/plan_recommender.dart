import '../data/plan_templates.dart';
import 'plan_template.dart';
import 'user_profile.dart';

class PlanRecommendation {
  const PlanRecommendation({
    required this.template,
    required this.score,
    required this.missingGear,
    required this.conflicts,
    required this.bestForYou,
  });

  final PlanTemplate template;
  final int score;

  /// Gear the plan needs that the user said they don't have.
  final Set<PlanGear> missingGear;

  /// Areas the user wants to protect that this plan loads heavily.
  final Set<ProtectedArea> conflicts;

  /// True for exactly one recommendation: the top pick the user can do today.
  final bool bestForYou;

  bool get isAvailable => missingGear.isEmpty && conflicts.isEmpty;
}

/// Ranks every template for a user. Deterministic and side-effect free so it
/// is easy to unit-test; the onboarding "choose your plan" step just renders
/// the result.
class PlanRecommender {
  const PlanRecommender();

  List<PlanRecommendation> recommend(UserProfile profile) {
    final templates = planTemplates;
    final scored = [
      for (final t in templates)
        (
          template: t,
          score: _score(t, profile),
          missing: t.gear.difference(profile.gear).intersection(_hardGear),
          conflicts: _conflicts(t, profile),
        ),
    ]..sort((a, b) => b.score.compareTo(a.score));

    final bestIndex = scored.indexWhere(
      (e) => e.missing.isEmpty && e.conflicts.isEmpty,
    );
    return [
      for (var i = 0; i < scored.length; i++)
        PlanRecommendation(
          template: scored[i].template,
          score: scored[i].score,
          missingGear: scored[i].missing,
          conflicts: scored[i].conflicts,
          bestForYou: i == bestIndex,
        ),
    ];
  }

  /// Gear a plan can't be done without. Walls, chairs and bands can be
  /// improvised; a bar can't.
  static const _hardGear = {PlanGear.pullUpBar, PlanGear.parallelBars};

  Set<ProtectedArea> _conflicts(PlanTemplate t, UserProfile p) {
    final a = p.protectedAreas;
    return {
      if (t.strainsWrists && a.contains(ProtectedArea.wrists))
        ProtectedArea.wrists,
      if (t.strainsShoulders && a.contains(ProtectedArea.shoulders))
        ProtectedArea.shoulders,
      if (t.strainsKnees && a.contains(ProtectedArea.knees))
        ProtectedArea.knees,
      if (t.strainsLowerBack && a.contains(ProtectedArea.lowerBack))
        ProtectedArea.lowerBack,
      if (t.invertsNeck && a.contains(ProtectedArea.neck)) ProtectedArea.neck,
    };
  }

  int _score(PlanTemplate t, UserProfile p) {
    var score = 0;

    score += switch (p.goal) {
      PrimaryGoal.getStronger => switch (t.focus) {
        PlanFocus.fullBody => 6,
        PlanFocus.skill =>
          t.skillId == 'push-up' || t.skillId == 'pull-up' ? 5 : 2,
        PlanFocus.core => 3,
        PlanFocus.legsGlutes => 3,
        _ => 0,
      },
      PrimaryGoal.toneBody => switch (t.focus) {
        PlanFocus.legsGlutes => 6,
        PlanFocus.core => 5,
        PlanFocus.fullBody => 4,
        _ => 0,
      },
      PrimaryGoal.improveFitness => switch (t.focus) {
        PlanFocus.conditioning => 6,
        PlanFocus.fullBody => 4,
        PlanFocus.mobility => 1,
        _ => 0,
      },
      PrimaryGoal.masterSkills => t.focus == PlanFocus.skill ? 6 : 1,
    };

    final extra = p.extraGoals;
    if (extra.contains('stronger-core') && t.focus == PlanFocus.core) {
      score += 2;
    }
    if (extra.contains('stronger-legs') && t.focus == PlanFocus.legsGlutes) {
      score += 2;
    }
    if (extra.contains('better-mobility') && t.focus == PlanFocus.mobility) {
      score += 3;
    }
    if (extra.contains('better-balance') &&
        const {'handstand', 'pistol-squat', 'l-sit'}.contains(t.skillId)) {
      score += 2;
    }
    if (extra.contains('stronger-upper-body') &&
        const {'push-up', 'pull-up', 'chin-up', 'dips'}.contains(t.skillId)) {
      score += 1;
    }

    // Body areas the user asked to focus on nudge the matching plan up.
    final areas = p.focusAreas;
    if (areas.contains('core') && t.focus == PlanFocus.core) score += 2;
    if ((areas.contains('glutes') || areas.contains('legs')) &&
        t.focus == PlanFocus.legsGlutes) {
      score += 2;
    }

    // Beginners are best served by the foundation plans; trained users by skill plans.
    if (p.level == PlanLevel.beginner && t.focus == PlanFocus.skill) {
      score -= 1;
    }
    if (p.level != PlanLevel.beginner &&
        t.stages.every((s) => s.level == PlanLevel.beginner) &&
        t.focus == PlanFocus.fullBody) {
      score -= 1;
    }
    if (p.level == PlanLevel.advanced && t.focus == PlanFocus.fullBody) {
      score -= 2;
    }
    if (p.level != PlanLevel.beginner && t.focus == PlanFocus.skill) {
      score += 1;
    }

    if (p.sessionMinutes <= 10 && t.focus == PlanFocus.conditioning) score += 1;
    return score;
  }
}
