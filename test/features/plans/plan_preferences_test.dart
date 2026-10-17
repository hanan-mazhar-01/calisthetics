import 'package:calisthenics/features/exercises/domain/exercise_lookup.dart';
import 'package:calisthenics/features/plans/data/plan_templates.dart';
import 'package:calisthenics/features/plans/domain/exercise_constraints.dart';
import 'package:calisthenics/features/plans/domain/plan_builder.dart';
import 'package:calisthenics/features/plans/domain/plan_template.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:calisthenics/features/plan/domain/plan_timeline.dart';
import 'package:calisthenics/features/user/domain/active_plan.dart';
import 'package:flutter_test/flutter_test.dart';

const builder = PlanBuilder();

List<BuiltSession> sessions(PlanTemplate t, UserProfile p, {int week = 1}) => [
  for (final d in builder.buildWeek(t, p, week: week).days)
    if (d.session != null) d.session!,
];

Set<int> mainVideos(List<BuiltSession> s) => {
  for (final x in s)
    for (final i in x.items) exerciseByNumber(i.exerciseNumber).videoNumber,
};

int totalSets(List<BuiltSession> s) =>
    s.fold(0, (a, x) => a + x.items.fold(0, (b, i) => b + i.sets));

void main() {
  midWeekStartTests();
  final foundation = planTemplates.first;
  final legs = planTemplates.firstWhere((t) => t.id == 'legs-and-glutes');

  test('every plan builds sessions with no repeated exercise', () {
    for (final t in planTemplates) {
      for (final level in PlanLevel.values) {
        for (final s in sessions(t, UserProfile(level: level))) {
          final videos = [
            for (final i in s.items)
              exerciseByNumber(i.exerciseNumber).videoNumber,
          ];
          expect(videos.toSet().length, videos.length, reason: t.id);
          expect(s.items, isNotEmpty, reason: t.id);
        }
      }
    }
  });

  test('areas to avoid never load a protected area', () {
    const avoid = {
      ProtectedArea.wrists,
      ProtectedArea.knees,
      ProtectedArea.lowerBack,
      ProtectedArea.shoulders,
      ProtectedArea.neck,
    };
    for (final t in planTemplates) {
      for (final s in sessions(
        t,
        const UserProfile(
          protectedAreas: avoid,
          sessionMinutes: 20,
          focusAreas: {'core', 'legs', 'arms'},
        ),
      )) {
        for (final n in [...s.warmUp, ...s.coolDown]) {
          expect(
            loadsProtectedArea(n, avoid),
            isFalse,
            reason: '${t.id} drill: ${exerciseByNumber(n).name}',
          );
        }
        for (final i in s.items) {
          expect(
            loadsProtectedArea(i.exerciseNumber, avoid),
            isFalse,
            reason: '${t.id}: ${exerciseByNumber(i.exerciseNumber).name}',
          );
        }
      }
    }
  });

  test('each session lasts the chosen time (within a minute)', () {
    final bad = <String>[];
    for (final t in planTemplates) {
      for (final level in PlanLevel.values) {
        for (final m in [10, 15, 20]) {
          for (final week in [1, 2, 3, 4]) {
            for (final s in sessions(
              t,
              UserProfile(sessionMinutes: m, level: level),
              week: week,
            )) {
              if ((s.estimatedMinutes - m).abs() > 1) {
                bad.add(
                  '${t.id}/${s.name} $m min $level w$week -> ${s.estimatedMinutes}',
                );
              }
            }
          }
        }
      }
    }
    expect(bad, isEmpty);
  });

  test('a longer chosen time means a longer session, near that time', () {
    for (final t in planTemplates) {
      var last = 0;
      for (final m in [10, 15, 20]) {
        final s = sessions(t, UserProfile(sessionMinutes: m));
        final longest = s.map((x) => x.estimatedMinutes).reduce(_max);
        expect(longest, greaterThanOrEqualTo(last), reason: '${t.id} $m');
        expect(longest, lessThanOrEqualTo(m + 4), reason: '${t.id} $m');
        last = longest;
      }
    }
    final short = sessions(foundation, const UserProfile(sessionMinutes: 10));
    final long = sessions(foundation, const UserProfile(sessionMinutes: 20));
    expect(totalSets(long), greaterThan(totalSets(short)));
  });

  test('focus areas bring matching exercises into the plan', () {
    final plain = mainVideos(sessions(legs, const UserProfile()));
    final core = mainVideos(
      sessions(legs, const UserProfile(focusAreas: {'core'})),
    );
    expect(core.difference(plain), isNotEmpty);
    final focused = sessions(legs, const UserProfile(focusAreas: {'core'}));
    expect(
      focused.every(
        (s) => s.items.any(
          (i) => const {10, 12, 13, 14, 15, 16}.contains(i.exerciseNumber),
        ),
      ),
      isTrue,
    );
  });

  test('level swaps exercises for harder rungs of the same ladder', () {
    final b = mainVideos(sessions(foundation, const UserProfile()));
    final i = mainVideos(
      sessions(foundation, const UserProfile(level: PlanLevel.intermediate)),
    );
    final a = mainVideos(
      sessions(foundation, const UserProfile(level: PlanLevel.advanced)),
    );
    expect(i.difference(b), isNotEmpty);
    expect(a.difference(i), isNotEmpty);
    // Standard Push-Up (4) appears once she is past the beginner rungs.
    expect(b.contains(4), isFalse);
    expect(i.contains(4), isTrue);
  });

  test('every focus area adds exercises that train it', () {
    const trains = {
      'core': {10, 11, 12, 13, 14, 15, 16},
      'legs': {17, 18, 19, 20, 21, 22, 23, 24},
      'glutes': {19, 21, 22, 23},
      'back': {6, 7, 8},
      'arms': {1, 2, 3, 4, 9},
      'shoulders': {5, 6, 9},
    };
    final mobility = planTemplates.firstWhere(
      (t) => t.id == 'express-conditioning',
    );
    for (final e in trains.entries) {
      final s = sessions(
        mobility,
        UserProfile(sessionMinutes: 20, focusAreas: {e.key}),
      );
      final numbers = {
        for (final x in s)
          for (final i in x.items) i.exerciseNumber,
      };
      expect(numbers.intersection(e.value), isNotEmpty, reason: e.key);
    }
  });

  test('focus exercises lead a session, and conflicts are reported', () {
    const upper = {1, 2, 3, 4, 5, 6, 7, 8, 9};
    final s = sessions(
      legs,
      const UserProfile(sessionMinutes: 20, focusAreas: {'arms', 'back'}),
    );
    for (final x in s) {
      expect(upper.contains(x.items.first.exerciseNumber), isTrue);
    }
    const blocked = UserProfile(
      focusAreas: {'shoulders', 'core'},
      protectedAreas: {ProtectedArea.shoulders, ProtectedArea.wrists},
    );
    expect(builder.unusableFocusAreas(blocked), contains('shoulders'));
    expect(
      builder.unusableFocusAreas(
        const UserProfile(focusAreas: {'core', 'legs'}),
      ),
      isEmpty,
    );
  });

  test('avoiding areas still leaves a real workout of 3+ exercises', () {
    for (final t in planTemplates) {
      for (final avoid in [
        {ProtectedArea.wrists},
        {ProtectedArea.wrists, ProtectedArea.shoulders},
        {ProtectedArea.wrists, ProtectedArea.knees, ProtectedArea.lowerBack},
      ]) {
        for (final s in sessions(
          t,
          UserProfile(
            level: PlanLevel.advanced,
            sessionMinutes: 10,
            focusAreas: const {'arms'},
            protectedAreas: avoid,
          ),
        )) {
          expect(
            s.items.length,
            greaterThanOrEqualTo(3),
            reason: '${t.id} $avoid',
          );
        }
      }
    }
    expect(
      builder.unusableFocusAreas(
        const UserProfile(
          focusAreas: {'arms'},
          protectedAreas: {ProtectedArea.wrists},
        ),
      ),
      isEmpty,
    );
  });

  test(
    'arms focus at advanced level with wrists protected still trains arms',
    () {
      const p = UserProfile(
        level: PlanLevel.advanced,
        sessionMinutes: 10,
        focusAreas: {'arms'},
        protectedAreas: {ProtectedArea.wrists},
      );
      for (final s in sessions(foundation, p)) {
        final numbers = s.items.map((i) => i.exerciseNumber).toSet();
        expect(numbers.contains(1), isTrue, reason: s.name); // wall push-up
        for (final n in [...numbers, ...s.warmUp, ...s.coolDown]) {
          expect(loadsProtectedArea(n, p.protectedAreas), isFalse);
        }
      }
    },
  );

  test('a warm-up or cool-down never repeats a movement', () {
    for (final t in planTemplates) {
      for (var week = 1; week <= 6; week++) {
        for (final s in sessions(t, const UserProfile(), week: week)) {
          for (final drills in [s.warmUp, s.coolDown]) {
            final videos = [
              for (final n in drills) exerciseByNumber(n).videoNumber,
            ];
            expect(videos.toSet().length, videos.length, reason: t.id);
          }
        }
      }
    }
  });

  test(
    'a focus never takes over the plan: its own exercises stay the majority',
    () {
      const lower = {17, 18, 19, 20, 21, 22, 23, 24};
      for (final m in [10, 15, 20]) {
        for (final s in sessions(
          legs,
          UserProfile(sessionMinutes: m, focusAreas: const {'core', 'arms'}),
        )) {
          final own = s.items
              .where((i) => lower.contains(i.exerciseNumber))
              .length;
          expect(
            own * 2,
            greaterThan(s.items.length),
            reason: '$m min ${s.name}',
          );
        }
      }
    },
  );

  test('each plan keeps to its own theme', () {
    // Leg plan: lower-body work only in the main block.
    final lower = {17, 18, 19, 20, 21, 22, 23, 24};
    for (final s in sessions(legs, const UserProfile())) {
      expect(
        s.items.map((i) => i.exerciseNumber).toSet().difference(lower),
        isEmpty,
      );
    }
    // Core plan: core exercises only.
    final core = planTemplates.firstWhere((t) => t.id == 'core-control');
    final coreSet = {10, 11, 12, 13, 14, 15, 16};
    for (final s in sessions(core, const UserProfile())) {
      expect(
        s.items.map((i) => i.exerciseNumber).toSet().difference(coreSet),
        isEmpty,
      );
    }
  });
}

int _max(int a, int b) => a > b ? a : b;

void midWeekStartTests() {
  test('a plan started mid-week begins with its first session', () {
    final push = planTemplates.firstWhere((t) => t.id == 'skill-push-up');
    final plan = ActivePlan(
      templateId: push.id,
      startDate: DateTime(2026, 10, 13), // a Tuesday
      profile: const UserProfile(daysPerWeek: 3),
    );
    final tl = PlanTimeline.build(
      template: push,
      plan: plan,
      history: const [],
      today: DateTime(2026, 10, 13, 9),
    );
    final first = tl.phases.first.days.first;
    expect(first.session.name, push.stages.first.sessions.first.name);
    // Plan weeks start on the start day: day 1 is that Tuesday itself, and
    // every one of the 4 weeks (28 days) has the full 3 sessions.
    expect(first.date, DateTime(2026, 10, 13));
    expect(PlanTimeline.leadingSkip(plan), 0);
    expect(tl.phases.length, 4);
    for (final ph in tl.phases) {
      expect(ph.days.length, 3);
    }
    expect(tl.totalDays, 12);
    expect(
      tl.phases.last.days.last.date.isBefore(DateTime(2026, 11, 10)),
      isTrue,
    );
  });
}
