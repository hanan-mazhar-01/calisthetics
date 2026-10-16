import 'package:calisthenics/features/exercises/data/exercise_catalog.dart';
import 'package:calisthenics/features/media/data/cloudinary_media_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repo = CloudinaryMediaRepository(cloudName: 'demo');

  test('exercise video URL uses the catalog file name as public id', () {
    final url = repo.exerciseVideo(exerciseCatalog.first)!;
    expect(
      url.toString(),
      'https://res.cloudinary.com/demo/video/upload/q_auto,f_auto,vc_auto/'
      'calesthetics/exercises/calesthetics_001_wall_push_up_beginner_v1.mp4',
    );
  });

  test('repeated exercises resolve to the shared video', () {
    final repeat = exerciseCatalog.firstWhere((e) => e.number == 39);
    expect(
      repo.exerciseVideo(repeat),
      repo.exerciseVideo(exerciseCatalog.first),
    );
  });

  test('unconfigured repository resolves nothing', () {
    const none = UnconfiguredMediaRepository();
    expect(none.exerciseVideo(exerciseCatalog.first), isNull);
    expect(none.image('welcome-hero'), isNull);
  });
}
