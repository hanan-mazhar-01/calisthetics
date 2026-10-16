import '../data/exercise_catalog.dart';
import 'exercise.dart';

final _byNumber = {for (final e in exerciseCatalog) e.number: e};

/// Exercise for a catalog number (1–115). Throws on unknown numbers — plan
/// templates are test-verified, so a miss is a programming error.
Exercise exerciseByNumber(int number) => _byNumber[number]!;

List<Exercise> exercisesInSection(String sectionId) => [
  for (final e in exerciseCatalog)
    if (e.sectionId == sectionId) e,
];

/// The ordered rungs (easiest → hardest) of one of the 8 skill ladders,
/// e.g. `ladderFor('pull-up')`. Every rung is kept, including early rungs
/// that reuse a foundation exercise's video (wall push-up, ...): the ladder
/// has to start at the beginning.
List<Exercise> ladderFor(String skillId) =>
    exercisesInSection('skill-$skillId');
