import '../../../shared/models/calisthenics_skill.dart';
import '../../plans/domain/plan_template.dart';

/// Everything the "All Plan" cards and the plan details page say about a
/// plan, worked out from the plan's own data (no text typed per plan, so it
/// can never disagree with what the plan really contains).

/// The body areas shown on the details page, in order.
const planAreaIds = ['arms', 'back', 'core', 'glutes', 'legs'];

const planAreaLabels = {
  'arms': 'Arms',
  'back': 'Back',
  'core': 'Core',
  'glutes': 'Glutes',
  'legs': 'Legs',
};

String planFocusLabel(PlanFocus f) => switch (f) {
  PlanFocus.fullBody => 'Full body',
  PlanFocus.core => 'Core',
  PlanFocus.legsGlutes => 'Legs & glutes',
  PlanFocus.conditioning => 'Conditioning',
  PlanFocus.mobility => 'Mobility',
  PlanFocus.skill => 'Skill',
};

String _levelLabel(PlanLevel l) => switch (l) {
  PlanLevel.beginner => 'Beginner',
  PlanLevel.intermediate => 'Intermediate',
  PlanLevel.advanced => 'Advanced',
};

String planGearLabel(PlanGear g) => switch (g) {
  PlanGear.pullUpBar => 'Pull-up bar',
  PlanGear.parallelBars => 'Parallel bars',
  PlanGear.wall => 'Wall',
  PlanGear.band => 'Band',
  PlanGear.chair => 'Chair',
};

/// "None", "Wall", or "Wall +2" when several things are needed.
String planEquipmentLabel(PlanTemplate t) {
  if (t.gear.isEmpty) return 'None';
  final names = [
    for (final g in PlanGear.values)
      if (t.gear.contains(g)) g,
  ]..sort((a, b) => a.index.compareTo(b.index));
  final first = planGearLabel(names.first);
  return names.length == 1 ? first : '$first +${names.length - 1}';
}

/// Each stage is a 4-week block.
int planWeeks(PlanTemplate t) => t.stages.length * 4;

/// "3 Stage : 12 Weeks".
String planLengthLabel(PlanTemplate t) =>
    '${t.stages.length} Stage : ${planWeeks(t)} Weeks';

/// Three short tags: what it is for, the level, and the focus.
List<String> planTags(PlanTemplate t) {
  final first = t.stages.first.level;
  final last = t.stages.last.level;
  final level = first == last ? _levelLabel(first) : '${_levelLabel(first)}+';
  return [t.tagline, level, planFocusLabel(t.focus)];
}

/// Which of [planAreaIds] the plan trains, from the sessions it contains.
Set<String> planAreas(PlanTemplate t) {
  final areas = <String>{};
  for (final stage in t.stages) {
    for (final s in stage.sessions) {
      switch (s.focus) {
        case PlanSessionFocus.upper:
          areas.addAll(['arms', 'back']);
        case PlanSessionFocus.lower:
          areas.addAll(['glutes', 'legs']);
        case PlanSessionFocus.core:
          areas.add('core');
        case PlanSessionFocus.full:
          areas.addAll(planAreaIds);
      }
    }
  }
  return areas;
}

/// Four plain lines on what following the plan gives.
List<String> planGains(PlanTemplate t) {
  final skill = t.skillId == null
      ? null
      : calisthenicsSkills.where((s) => s.id == t.skillId).firstOrNull;
  final main = switch (t.focus) {
    PlanFocus.fullBody => 'Strength across your upper body, core and legs.',
    PlanFocus.core => 'A stronger, steadier core.',
    PlanFocus.legsGlutes => 'Stronger legs and glutes.',
    PlanFocus.conditioning => 'More stamina from short, focused sessions.',
    PlanFocus.mobility => 'Looser joints and easier movement.',
    PlanFocus.skill =>
      'Real progress towards your ${skill?.label.toLowerCase() ?? 'skill'}.',
  };
  return [
    main,
    'A coached video for every exercise.',
    t.stages.length == 1
        ? 'A clear 4-week block you can repeat and build on.'
        : '${t.stages.length} stages that build one on the other.',
    'Your progress saved day by day.',
  ];
}
