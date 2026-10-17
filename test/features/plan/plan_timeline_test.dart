import 'package:calisthenics/features/plan/domain/plan_timeline.dart';
import 'package:calisthenics/features/plans/data/plan_templates.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:calisthenics/features/user/domain/active_plan.dart';
import 'package:calisthenics/features/user/domain/completed_session.dart';
import 'package:flutter_test/flutter_test.dart';

final _template = planTemplates.firstWhere(
  (t) => t.id == 'foundation-full-body',
);
const _profile = UserProfile(daysPerWeek: 3);

CompletedSession _done(DateTime at) => CompletedSession(
  finishedAt: at,
  templateId: _template.id,
  sessionName: 's',
  durationSeconds: 600,
  exerciseNumbers: const [1],
);

PlanTimeline _build({
  required DateTime start,
  required DateTime today,
  List<CompletedSession> history = const [],
}) => PlanTimeline.build(
  template: _template,
  plan: ActivePlan(
    templateId: _template.id,
    startDate: start,
    profile: _profile,
  ),
  history: history,
  today: today,
);

void main() {
  // Monday 12 Oct 2026.
  final monday = DateTime(2026, 10, 12);

  test('a block has four phases; rest days are skipped and days count up', () {
    final t = _build(start: monday, today: monday);
    expect(t.phases.length, 4);
    expect(t.phases.first.days.length, 3);
    final numbers = [
      for (final p in t.phases) ...p.days.map((d) => d.dayNumber),
    ];
    expect(numbers, List.generate(12, (i) => i + 1));
    expect(t.phases[1].firstDay, 4);
    expect(t.phases[1].lastDay, 6);
  });

  test('the hero is today\'s session and done days are marked', () {
    final t = _build(
      start: monday,
      today: DateTime(2026, 10, 14, 9),
      history: [_done(DateTime(2026, 10, 12, 8))],
    );
    expect(t.phases.first.days[0].status, TimelineStatus.done);
    expect(t.hero!.dayNumber, 2); // Wednesday
    expect(t.hero!.status, TimelineStatus.today);
    expect(t.phases.first.percent, 33);
  });

  test(
    'a skipped day is missed and the hero moves to the next upcoming day',
    () {
      final t = _build(start: monday, today: DateTime(2026, 10, 15));
      expect(t.phases.first.days[0].status, TimelineStatus.missed);
      expect(t.hero!.dayNumber, 3); // Friday 16 Oct
    },
  );

  test('a plan started mid-week has no days before its start date', () {
    final t = _build(
      start: DateTime(2026, 10, 14),
      today: DateTime(2026, 10, 14),
    );
    expect(t.phases.first.days.first.date, DateTime(2026, 10, 14));
    expect(t.phases.first.days.first.dayNumber, 1);
  });

  test('after four weeks the next block starts as phases 1–4 again', () {
    final t = _build(
      start: monday,
      today: monday.add(const Duration(days: 28)),
    );
    expect(t.phases.first.index, 1);
    expect(t.phases.first.weekNumber, 5);
    expect(t.phases.first.firstDay, 13);
  });

  test(
    'two workouts on one day tick off two days (doing the next one early)',
    () {
      final t = _build(
        start: monday,
        today: monday,
        history: [
          _done(monday.add(const Duration(hours: 9))),
          _done(monday.add(const Duration(hours: 18))),
        ],
      );
      final days = [for (final p in t.phases) ...p.days];
      expect(days[0].status, TimelineStatus.done);
      expect(days[1].status, TimelineStatus.done);
      expect(days[2].status, isNot(TimelineStatus.done));
      expect(t.doneDays, 2);
    },
  );
}
