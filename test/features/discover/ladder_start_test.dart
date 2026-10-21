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

  test('free: no Discover video plays, even one the own plan uses', () {
    const free = ExerciseAccessPolicy(isPremium: false);
    // #39 (a ladder rung) shares its video with #1 (wall push-up).
    expect(free.canPlayVideo(exerciseByNumber(39)), isFalse);
    expect(free.canPlayVideo(exerciseByNumber(1)), isFalse);
    expect(
      const ExerciseAccessPolicy(isPremium: true)
          .canPlayVideo(exerciseByNumber(39)),
      isTrue,
    );
  });
}
