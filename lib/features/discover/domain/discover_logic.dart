import '../../exercises/data/exercise_catalog.dart';
import '../../exercises/domain/exercise.dart';
import '../../exercises/domain/exercise_lookup.dart';
import '../../plans/domain/plan_template.dart';
import '../../user/domain/active_plan.dart';
import '../../user/domain/completed_session.dart';

/// Equipment groups used by the Discover filter. The catalog's equipment
/// field is free text ("Pull-up bar; band optional"), so it is mapped to
/// these groups by keyword.
enum EquipmentTag {
  none('No equipment'),
  mat('Mat'),
  wall('Wall'),
  bar('Bar'),
  parallel('Parallel bars'),
  band('Band'),
  support('Chair, box or step');

  const EquipmentTag(this.label);
  final String label;
}

Set<EquipmentTag> equipmentTagsOf(Exercise e) {
  final s = e.equipment.toLowerCase();
  return {
    if (s.contains('none')) EquipmentTag.none,
    if (s.contains('mat')) EquipmentTag.mat,
    if (s.contains('wall')) EquipmentTag.wall,
    if (s.contains('pull-up bar') || s.contains('low bar')) EquipmentTag.bar,
    if (s.contains('parallel') || s.contains('parallettes'))
      EquipmentTag.parallel,
    if (s.contains('band')) EquipmentTag.band,
    if (s.contains('chair') ||
        s.contains('box') ||
        s.contains('step') ||
        s.contains('support') ||
        s.contains('elevated') ||
        s.contains('stable surface'))
      EquipmentTag.support,
  };
}

/// Discover filters. An empty set means "no restriction"; within a set an
/// exercise matches if it fits any selected value.
class DiscoverFilters {
  const DiscoverFilters({
    this.equipment = const {},
    this.levels = const {},
    this.favoritesOnly = false,
  });

  final Set<EquipmentTag> equipment;
  final Set<ExerciseLevel> levels;
  final bool favoritesOnly;

  bool get isActive =>
      equipment.isNotEmpty || levels.isNotEmpty || favoritesOnly;

  DiscoverFilters copyWith({
    Set<EquipmentTag>? equipment,
    Set<ExerciseLevel>? levels,
    bool? favoritesOnly,
  }) => DiscoverFilters(
    equipment: equipment ?? this.equipment,
    levels: levels ?? this.levels,
    favoritesOnly: favoritesOnly ?? this.favoritesOnly,
  );
}

/// Searches all catalog exercises by name (case-insensitive, every word of
/// the query must appear) and applies [filters]. Catalog order is kept.
List<Exercise> searchExercises(
  String query, {
  DiscoverFilters filters = const DiscoverFilters(),
  Set<int> favorites = const {},
}) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  return [
    for (final e in exerciseCatalog)
      if (_matches(e, words, filters, favorites)) e,
  ];
}

bool _matches(
  Exercise e,
  List<String> words,
  DiscoverFilters f,
  Set<int> favorites,
) {
  final name = e.name.toLowerCase();
  if (!words.every(name.contains)) return false;
  if (f.levels.isNotEmpty && !f.levels.contains(e.level)) return false;
  if (f.equipment.isNotEmpty &&
      equipmentTagsOf(e).intersection(f.equipment).isEmpty) {
    return false;
  }
  if (f.favoritesOnly && !favorites.contains(e.number)) return false;
  return true;
}

/// Skill id of a skill-ladder exercise (`skill-pull-up` -> `pull-up`), or null.
String? skillIdOfSection(String sectionId) =>
    sectionId.startsWith('skill-') ? sectionId.substring(6) : null;

/// Index of [e] on its own ladder, or null if it is not on one. Entries that
/// reuse another entry's video map to that entry's rung.
int? rungIndexOf(Exercise e) {
  final skill = skillIdOfSection(e.sectionId);
  if (skill == null) return null;
  final ladder = ladderFor(skill);
  final i = ladder.indexWhere((r) => r.videoNumber == e.videoNumber);
  return i < 0 ? null : i;
}

/// The rung of [skillId] the user is on.
///
/// * If the active plan is this skill's plan: the hardest rung that the
///   current stage trains (clamped to the plan's stage list).
/// * Otherwise: the hardest rung of this ladder found in her history.
/// * Otherwise: the first rung.
Exercise currentRungFor(
  String skillId, {
  ActivePlan? plan,
  PlanTemplate? template,
  List<CompletedSession> history = const [],
}) {
  final ladder = ladderFor(skillId);
  if (plan != null && template != null && template.skillId == skillId) {
    final stage =
        template.stages[plan.stageIndex.clamp(0, template.stages.length - 1)];
    var best = -1;
    for (final s in stage.sessions) {
      for (final item in s.items) {
        // Plans may use the foundation twin of a rung, so match by video.
        final video = exerciseByNumber(item.exerciseNumber).videoNumber;
        final i = ladder.indexWhere((r) => r.videoNumber == video);
        if (i > best) best = i;
      }
    }
    if (best >= 0) return ladder[best];
  }
  var best = 0;
  for (final session in history) {
    for (final n in session.exerciseNumbers) {
      final video = exerciseByNumber(n).videoNumber;
      final i = ladder.indexWhere((r) => r.videoNumber == video);
      if (i > best) best = i;
    }
  }
  return ladder[best];
}

/// Skill-ladder neighbours of an exercise, for "easier / harder" links.
({Exercise? easier, Exercise? harder}) neighboursOf(Exercise e) {
  final i = rungIndexOf(e);
  if (i == null) return (easier: null, harder: null);
  final ladder = ladderFor(skillIdOfSection(e.sectionId)!);
  return (
    easier: i > 0 ? ladder[i - 1] : null,
    harder: i < ladder.length - 1 ? ladder[i + 1] : null,
  );
}
