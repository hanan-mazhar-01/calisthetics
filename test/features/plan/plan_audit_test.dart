import 'package:calisthenics/features/plan/domain/plan_timeline.dart';
import 'package:calisthenics/features/plans/data/plan_templates.dart';
import 'package:calisthenics/features/plans/domain/plan_builder.dart';
import 'package:calisthenics/features/plans/domain/plan_template.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:calisthenics/features/user/domain/active_plan.dart';
import 'package:flutter_test/flutter_test.dart';

String sig(BuiltSession s) =>
    '${s.warmUp}|${s.items.map((i) => '${i.exerciseNumber}x${i.sets}')}|${s.coolDown}';

void main() {
  const builder = PlanBuilder();
  final profiles = <String, UserProfile>{
    'default': const UserProfile(),
    'advanced20': const UserProfile(
      level: PlanLevel.advanced,
      sessionMinutes: 20,
    ),
    'int10-arms': const UserProfile(
      level: PlanLevel.intermediate,
      sessionMinutes: 10,
      focusAreas: {'arms'},
    ),
    'avoid-wrists': const UserProfile(
      sessionMinutes: 15,
      protectedAreas: {ProtectedArea.wrists},
    ),
    'avoid-three': const UserProfile(
      sessionMinutes: 15,
      protectedAreas: {
        ProtectedArea.wrists,
        ProtectedArea.knees,
        ProtectedArea.lowerBack,
      },
    ),
    '5days': const UserProfile(daysPerWeek: 5, sessionMinutes: 15),
    '2days': const UserProfile(daysPerWeek: 2, sessionMinutes: 15),
  };

  test('every training day of every plan opens a full, distinct workout', () {
    final problems = <String>[];
    for (final t in planTemplates) {
      for (final pe in profiles.entries) {
        for (var startDay = 12; startDay <= 18; startDay++) {
          final start = DateTime(2026, 10, startDay);
          final plan = ActivePlan(
            templateId: t.id,
            startDate: start,
            profile: pe.value,
            stageIndex: builder.startingStage(t, pe.value),
          );
          final tl = PlanTimeline.build(
            template: t,
            plan: plan,
            history: const [],
            today: start,
          );
          final seen = <String, int>{};
          for (final ph in tl.phases) {
            for (final d in ph.days) {
              final tag = '${t.id}/${pe.key}/start$startDay/day${d.dayNumber}';
              // What the Day screen resolves for this day.
              final week = builder.buildWeek(
                t,
                plan.profile,
                week: d.weekNumber,
                stageIndex: plan.stageIndex,
                skipLeadingDays: d.weekNumber == 1
                    ? PlanTimeline.leadingSkip(plan)
                    : 0,
              );
              final opened = week.days[d.weekday].session;
              if (opened == null) {
                problems.add('$tag opens EMPTY');
                continue;
              }
              if (sig(opened) != sig(d.session)) {
                problems.add('$tag screen != list');
              }
              if (d.session.items.length < 3) {
                problems.add('$tag has ${d.session.items.length} exercises');
              }
              if (d.session.warmUp.isEmpty || d.session.coolDown.isEmpty) {
                problems.add('$tag no warm-up/cool-down');
              }
              final prev = seen[sig(d.session)];
              // With three areas ruled out only a handful of exercises are
              // left, so repeats are unavoidable there.
              if (prev != null && pe.key != 'avoid-three') {
                problems.add('$tag same as day$prev');
              }
              seen[sig(d.session)] = d.dayNumber;
            }
          }
        }
      }
    }
    expect(problems.take(30).toList(), isEmpty);
  });
}
