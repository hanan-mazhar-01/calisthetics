import 'package:calisthenics/features/discover/domain/exercise_access_policy.dart';
import 'package:calisthenics/features/exercises/domain/exercise_lookup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'every ladder starts at its first rung, including shared-video ones',
    () {
      final push = ladderFor('push-up');
      expect(push.length, 8);
      expect(push.first.name, 'Wall Push-Up');
      expect(ladderFor('pistol-squat').first.name, 'Supported Split Squat');
      expect(ladderFor('dips').first.name, 'Bench Support Hold');
    },
  );

  test('a plan using the foundation twin unlocks the ladder rung', () {
    // Push-up plan uses #1 (wall push-up); the ladder rung is #39.
    const policy = ExerciseAccessPolicy(
      isPremium: false,
      planExerciseNumbers: {1, 2, 3, 4},
    );
    expect(policy.canPlayVideo(exerciseByNumber(39)), isTrue);
    expect(policy.canPlayVideo(exerciseByNumber(46)), isFalse);
  });
}
