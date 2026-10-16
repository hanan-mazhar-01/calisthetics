import 'package:calisthenics/features/plans/data/plan_templates.dart';
import 'package:calisthenics/features/plans/domain/plan_builder.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a session card is pictured by its own first exercise, never by a '
      'focus exercise added in front of it', () {
    const builder = PlanBuilder();
    final template = planTemplates.firstWhere(
      (t) => t.id == 'foundation-full-body',
    );
    // Glutes focus puts glute work first in the list; the "Upper body" day's
    // picture must still be an upper-body exercise from the template.
    final profile = const UserProfile().copyWith(
      focusAreas: {'glutes'},
      sessionMinutes: 20,
    );
    final upper = builder
        .buildWeek(template, profile, week: 1)
        .days
        .map((d) => d.session)
        .whereType<BuiltSession>()
        .firstWhere((s) => s.name.startsWith('Upper'));
    const glutes = {19, 21, 22, 23};
    expect(glutes.contains(upper.items.first.exerciseNumber), isTrue);
    expect(glutes.contains(upper.cover), isFalse);
    expect(upper.items.any((i) => i.exerciseNumber == upper.cover), isTrue);
  });

  test('own exercises exclude the focus ones added in front', () {
    const builder = PlanBuilder();
    final template = planTemplates.firstWhere(
      (t) => t.id == 'foundation-full-body',
    );
    final profile = const UserProfile().copyWith(
      focusAreas: {'glutes'},
      sessionMinutes: 20,
    );
    for (final s
        in builder
            .buildWeek(template, profile, week: 1)
            .days
            .map((d) => d.session)
            .whereType<BuiltSession>()) {
      expect(s.ownNumbers, isNotEmpty);
      expect(s.ownNumbers.first, s.cover);
      expect(s.ownNumbers.length, lessThan(s.items.length));
    }
  });
}
