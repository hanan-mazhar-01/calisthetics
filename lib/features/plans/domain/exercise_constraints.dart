import '../../exercises/domain/exercise.dart';
import 'plan_template.dart';
import 'user_profile.dart';

/// Exercises that load an area, so they are steered away from when the user
/// asks to protect it. This adjusts exercise choice — it is not medical
/// advice. Numbers are catalog exercise numbers.
const Map<ProtectedArea, Set<int>> areaLoads = {
  ProtectedArea.wrists: {
    2, 3, 4, 5, 6, 9, 11, 12, 28, 30, 101, // foundation + mobility
    43, 44, 45, 46, // push-up variations
    54, 55, 56, 57, 58, 59, 60, // L-sit (support on hands)
    61, 62, 63, 64, 65, 66, 67, 68, // handstand
    69, 70, 71, 72, 73, 74, 75, // dips
  },
  ProtectedArea.shoulders: {
    4, 5, 6, 9, 30, 101,
    31, 32, 33, 34, 35, 36, 37, 38, // pull-ups
    43, 44, 45, 46,
    62, 63, 64, 65, 66, 67, 68,
    69, 70, 71, 72, 73, 74, 75,
    76, 77, 78, 79, 80, 81, 82, 83, // chin-ups
    84, 85, 86, 87, 88, 89, 90, // hanging core
  },
  ProtectedArea.knees: {
    19, 20, 23, 26, 27, 28, 29, 30, 100,
    47, 48, 49, 50, 51, 52, 53, // pistol squat ladder
  },
  ProtectedArea.lowerBack: {
    15, 16, 28, 30, 101,
    84, 85, 86, 87, 88, 89, 90, // hanging leg raises
  },
  ProtectedArea.neck: {
    5, 15, 16, 101,
    62, 63, 64, 65, 66, 67, 68, // inverted work
  },
};

/// Exercises that need gear (any one of the listed items). Mat work and
/// bodyweight-only exercises are not listed.
const Map<int, Set<PlanGear>> exerciseGear = {
  1: {PlanGear.wall},
  2: {PlanGear.wall, PlanGear.chair, PlanGear.parallelBars},
  7: {PlanGear.pullUpBar},
  8: {PlanGear.band},
  9: {PlanGear.parallelBars},
  17: {PlanGear.chair},
  20: {PlanGear.wall, PlanGear.chair},
  23: {PlanGear.chair},
  98: {PlanGear.wall},
  99: {PlanGear.wall},
  104: {PlanGear.wall},
};

/// Whether [exerciseNumber] loads any area in [protected].
bool loadsProtectedArea(int exerciseNumber, Set<ProtectedArea> protected) {
  for (final area in protected) {
    if (areaLoads[area]?.contains(exerciseNumber) ?? false) return true;
  }
  return false;
}

/// Whether [e] suits this profile's protected areas, gear and level cap.
bool exerciseAllowedFor(Exercise e, UserProfile p) {
  if (loadsProtectedArea(e.number, p.protectedAreas)) return false;
  final need = exerciseGear[e.number];
  if (need != null && need.intersection(p.gear).isEmpty) return false;
  final cap = switch (p.level) {
    PlanLevel.beginner => ExerciseLevel.begInt,
    PlanLevel.intermediate => ExerciseLevel.intermediate,
    PlanLevel.advanced => ExerciseLevel.advanced,
  };
  return e.level.index <= cap.index;
}
