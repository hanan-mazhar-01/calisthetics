import 'package:calisthenics/features/exercises/data/exercise_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog has all 115 exercises numbered 1..115', () {
    expect(exerciseCatalog.length, 115);
    expect(
      exerciseCatalog.map((e) => e.number),
      List.generate(115, (i) => i + 1),
    );
  });

  test('98 unique videos; 17 exercises reuse another entry\'s video', () {
    expect(exerciseCatalog.map((e) => e.videoFile).toSet().length, 98);
    expect(exerciseCatalog.where((e) => e.sharesVideo).length, 17);
  });

  test('video file names follow the naming rule', () {
    final pattern = RegExp(
      r'^calesthetics_\d{3}_[a-z0-9_]+_(beginner|beg-int|intermediate|int-adv|advanced)_v1\.mp4$',
    );
    for (final e in exerciseCatalog) {
      expect(pattern.hasMatch(e.videoFile), isTrue, reason: e.videoFile);
      expect(
        e.videoFile.contains('_${e.videoNumber.toString().padLeft(3, '0')}_'),
        isTrue,
        reason: e.name,
      );
    }
  });

  test('every exercise has filming details to show in the app', () {
    for (final e in exerciseCatalog) {
      expect(e.startingPosition, isNotNull, reason: e.name);
      expect(e.steps, isNotEmpty, reason: e.name);
    }
  });

  test('every exercise belongs to a known section', () {
    final ids = exerciseSections.map((s) => s.id).toSet();
    for (final e in exerciseCatalog) {
      expect(ids.contains(e.sectionId), isTrue, reason: e.name);
    }
  });
}
