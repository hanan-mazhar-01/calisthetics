import 'package:calisthenics/features/exercises/domain/exercise_lookup.dart';
import 'package:calisthenics/features/plan/domain/plan_timeline.dart';
import 'package:calisthenics/features/plan/domain/cover_pictures.dart';
import 'package:calisthenics/features/plans/data/plan_templates.dart';
import 'package:calisthenics/features/plans/domain/plan_builder.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('day cards do not all wear the same picture', () {
    const builder = PlanBuilder();
    for (final t in planTemplates) {
      final days = <TimelineDay>[];
      var n = 1;
      for (var w = 1; w <= 4; w++) {
        for (final d
            in builder.buildWeek(t, const UserProfile(), week: w).days) {
          final s = d.session;
          if (s == null) continue;
          days.add(
            TimelineDay(
              dayNumber: n++,
              date: DateTime(2026, 1, n),
              weekNumber: w,
              weekday: d.weekday,
              session: s,
              status: TimelineStatus.upcoming,
            ),
          );
        }
      }
      final covers = coverPictures(days);
      expect(covers.length, days.length, reason: t.id);
      final videos = [
        for (final d in days)
          exerciseByNumber(covers[d.dayNumber]!).videoNumber,
      ];
      // never the same picture two days running, and plenty of variety
      for (var i = 1; i < videos.length; i++) {
        expect(videos[i], isNot(videos[i - 1]), reason: '${t.id} day ${i + 1}');
      }
      expect(
        videos.toSet().length,
        greaterThan(videos.length ~/ 3),
        reason: t.id,
      );
    }
  });
}
