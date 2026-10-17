import 'package:calisthenics/features/plans/data/plan_templates.dart';
import 'package:calisthenics/features/plans/domain/plan_builder.dart';
import 'package:calisthenics/features/plans/domain/plan_template.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every timed set in every plan is 30 s (the length of the videos)', () {
    const builder = PlanBuilder();
    for (final t in planTemplates) {
      for (final level in PlanLevel.values) {
        for (final minutes in [10, 15, 20]) {
          final p = const UserProfile().copyWith(
            level: level,
            sessionMinutes: minutes,
          );
          for (var w = 1; w <= 4; w++) {
            for (final d in builder.buildWeek(t, p, week: w).days) {
              for (final i in d.session?.items ?? const <BuiltItem>[]) {
                if (i.holdSeconds != null) {
                  expect(i.holdSeconds, 30, reason: '${t.id} wk$w');
                }
              }
            }
          }
        }
      }
    }
  });
}
