import '../../exercises/domain/exercise_lookup.dart';
import '../data/plan_templates.dart';
import 'exercise_constraints.dart';
import 'plan_template.dart';
import 'user_profile.dart';

class BuiltItem {
  const BuiltItem({
    required this.exerciseNumber,
    required this.sets,
    this.reps,
    this.holdSeconds,
    this.perSide = false,
  });

  final int exerciseNumber;
  final int sets;
  final int? reps;
  final int? holdSeconds;
  final bool perSide;
}

class BuiltSession {
  const BuiltSession({
    required this.name,
    required this.warmUp,
    required this.items,
    required this.coolDown,
    required this.estimatedMinutes,
    this.coverNumber,
    this.ownNumbers = const [],
  });

  final String name;

  /// The exercise that stands for the session on its card: the session's own
  /// first exercise, not a focus exercise added in front of it (which can be
  /// for another body area than the session's name).
  final int? coverNumber;

  /// The session's own exercises (without the focus ones added in front),
  /// best first: what its card picture can be chosen from.
  final List<int> ownNumbers;

  /// [coverNumber], or the first exercise when none was set.
  int get cover => coverNumber ?? items.first.exerciseNumber;

  /// Catalog exercise numbers, each done for [PlanBuilder.drillSeconds].
  final List<int> warmUp;
  final List<BuiltItem> items;
  final List<int> coolDown;
  final int estimatedMinutes;
}

/// One day of a built week: a workout, or a rest day (`session == null`).
class PlannedDay {
  const PlannedDay({required this.weekday, this.session});

  /// 0 = Monday … 6 = Sunday.
  final int weekday;
  final BuiltSession? session;

  bool get isRest => session == null;
}

class BuiltWeek {
  const BuiltWeek({
    required this.weekNumber,
    required this.stageIndex,
    required this.isDeload,
    required this.days,
  });

  final int weekNumber;
  final int stageIndex;

  /// Every 4th week trims volume so the body can absorb the training.
  final bool isDeload;
  final List<PlannedDay> days;
}

/// Turns a [PlanTemplate] plus a [UserProfile] into concrete weeks:
/// which weekdays train, which exercises, how many sets/reps, and how that
/// grows week to week (progression). Pure and deterministic.
class PlanBuilder {
  const PlanBuilder();

  static const drillSeconds = 30;
  static const _restSeconds = 10;
  static const _openingSeconds = 10;

  /// Weekdays (0 = Monday) a plan trains on for [daysPerWeek] sessions.
  static List<int> trainingWeekdays(int daysPerWeek) =>
      _trainingDays[daysPerWeek.clamp(1, 6)]!;

  static const _trainingDays = {
    1: [0],
    2: [0, 3],
    3: [0, 2, 4],
    4: [0, 1, 3, 4],
    5: [0, 1, 2, 4, 5],
    6: [0, 1, 2, 3, 4, 5],
  };

  // Warm-up and cool-down drills: the first ones are the defaults, the rest
  // are stand-ins used when an area she protects rules a default out.
  static const _warmUps = {
    PlanSessionFocus.upper: [92, 93, 95, 94, 96, 91],
    PlanSessionFocus.lower: [97, 98, 99, 25, 91, 96],
    PlanSessionFocus.core: [96, 97, 25, 91, 92, 99],
    PlanSessionFocus.full: [25, 92, 97, 96, 91, 99],
  };
  static const _coolDowns = {
    PlanSessionFocus.upper: [104, 102, 103, 105],
    PlanSessionFocus.lower: [103, 101, 102, 105],
    PlanSessionFocus.core: [102, 103, 105, 104],
    PlanSessionFocus.full: [103, 104, 105, 102, 101],
  };
  static const _warmUpCount = 3;
  static const _coolDownCount = {
    PlanSessionFocus.upper: 2,
    PlanSessionFocus.lower: 2,
    PlanSessionFocus.core: 2,
    PlanSessionFocus.full: 3,
  };

  /// The first [count] drills from [candidates] that suit her protected areas
  /// and gear.
  List<int> _drills(List<int> candidates, int count, UserProfile p) {
    final out = <int>[];
    final videos = <int>{};
    for (final n in candidates) {
      if (out.length == count) break;
      // #25 and #91 are the same movement (one video): use it once.
      if (!videos.add(exerciseByNumber(n).videoNumber)) continue;
      if (loadsProtectedArea(n, p.protectedAreas)) continue;
      final need = exerciseGear[n];
      if (need != null && need.intersection(p.gear).isEmpty) continue;
      out.add(n);
    }
    return out;
  }

  static const _upper = [
    PlanItem.reps(8, 3, 12),
    PlanItem.reps(6, 2, 10),
    PlanItem.reps(2, 3, 8),
    PlanItem.reps(3, 3, 6),
    PlanItem.reps(7, 3, 8),
  ];
  static const _lower = [
    PlanItem.reps(18, 3, 12),
    PlanItem.reps(21, 3, 12),
    PlanItem.reps(24, 3, 12),
    PlanItem.reps(17, 3, 10),
    PlanItem.reps(19, 2, 8, perSide: true),
    PlanItem.reps(23, 2, 8, perSide: true),
  ];
  static const _core = [
    PlanItem.reps(10, 3, 8),
    PlanItem.hold(12, 3, 20),
    PlanItem.hold(13, 3, 20),
    PlanItem.reps(16, 3, 10),
    PlanItem.hold(14, 2, 15, perSide: true),
    PlanItem.hold(15, 3, 15),
  ];

  /// Accessory pools by the focus ids used on the onboarding body-map step.
  static const _focusPools = {
    'core': [_core],
    'legs': [_lower],
    'glutes': [_glutes],
    'shoulders': [_shoulders],
    'arms': [_arms],
    'back': [_back],
  };

  // Mobility plans use mobility work for their focus and top-ups, not
  // strength exercises.
  static const _mobilityFocusPools = {
    'shoulders': [_mobShoulders],
    'arms': [_mobShoulders],
    'back': [_mobBack],
    'core': [_mobBack],
    'legs': [_mobHips],
    'glutes': [_mobHips],
  };
  static const _mobShoulders = [
    PlanItem.hold(93, 2, 30),
    PlanItem.hold(92, 2, 30),
    PlanItem.hold(95, 2, 30),
    PlanItem.hold(104, 2, 30),
    PlanItem.hold(94, 2, 30),
  ];
  static const _mobBack = [
    PlanItem.hold(96, 2, 30),
    PlanItem.hold(102, 2, 30),
    PlanItem.hold(101, 2, 30),
    PlanItem.hold(105, 2, 30),
  ];
  static const _mobHips = [
    PlanItem.hold(97, 2, 30),
    PlanItem.hold(98, 2, 30),
    PlanItem.hold(99, 2, 30),
    PlanItem.hold(103, 2, 30),
    PlanItem.hold(100, 2, 30),
  ];
  static const _mobilitySessionPools = {
    PlanSessionFocus.upper: _mobShoulders,
    PlanSessionFocus.lower: _mobHips,
    PlanSessionFocus.core: _mobBack,
    PlanSessionFocus.full: [..._mobBack, ..._mobHips, ..._mobShoulders],
  };

  // Exercises that train one body area, from the 115-exercise guide.
  static const _glutes = [
    PlanItem.reps(21, 3, 12),
    PlanItem.reps(22, 3, 8),
    PlanItem.reps(23, 3, 10),
    PlanItem.reps(19, 3, 10),
  ];
  static const _shoulders = [
    PlanItem.reps(6, 3, 8),
    PlanItem.hold(9, 3, 15),
    PlanItem.reps(5, 3, 6),
  ];
  static const _arms = [
    PlanItem.reps(1, 3, 10),
    PlanItem.reps(2, 3, 8),
    PlanItem.reps(3, 3, 8),
    PlanItem.hold(9, 3, 15),
    PlanItem.reps(4, 3, 6),
    // Pulling works the arms too, and keeps the wrists free.
    PlanItem.reps(8, 3, 12),
    PlanItem.reps(7, 3, 8),
  ];
  static const _back = [
    PlanItem.reps(8, 3, 12),
    PlanItem.reps(7, 3, 8),
    PlanItem.reps(6, 2, 8),
  ];

  static const _sessionPools = {
    PlanSessionFocus.upper: _upper,
    PlanSessionFocus.lower: _lower,
    PlanSessionFocus.core: _core,
    PlanSessionFocus.full: [..._lower, ..._core, ..._upper],
  };

  /// Focus areas in [p] that her avoid areas leave no exercise for, so they
  /// can't shape her sessions (e.g. focus on shoulders while avoiding them).
  List<String> unusableFocusAreas(UserProfile p) => [
    for (final area in p.focusAreas)
      if (!(_focusPools[area] ?? const <List<PlanItem>>[]).any(
        (pool) => pool.any(
          (i) => exerciseAllowedFor(exerciseByNumber(i.exerciseNumber), p),
        ),
      ))
        area,
  ];

  /// Steps up each exercise ladder for a user's level.
  static int _levelSteps(PlanLevel l) => switch (l) {
    PlanLevel.beginner => 0,
    PlanLevel.intermediate => 1,
    PlanLevel.advanced => 2,
  };

  /// Progression ladders over the 115-exercise catalog, easiest first. A
  /// higher level swaps an exercise for the next rung(s) of its own ladder.
  static const _ladders = [
    [1, 2, 3, 4, 5], // wall -> incline -> knee -> standard -> pike push-up
    [8, 7], // band row -> inverted row
    [12, 13, 15], // knee -> forearm plank -> hollow hold
    [10, 11, 16], // dead bug -> bird dog -> reverse crunch
    [17, 18, 19, 23], // chair squat -> squat -> lunge -> step-up
    [20, 23], // supported split squat -> step-up
    [21, 22], // glute bridge -> single-leg bridge
    [25, 26, 27, 29, 28, 30], // march -> jacks -> knees -> climbers -> burpee
  ];

  /// [i] moved [steps] rungs up its ladder, stepping back down when that rung
  /// loads an area she protects (so level never removes an exercise that a
  /// gentler rung of the same ladder could still provide).
  PlanItem _shiftItem(PlanItem i, int steps, UserProfile p) {
    if (steps == 0) return i;
    for (final ladder in _ladders) {
      final at = ladder.indexOf(i.exerciseNumber);
      if (at < 0) continue;
      for (var k = steps; k >= 0; k--) {
        final to = ladder[(at + k).clamp(0, ladder.length - 1)];
        final e = exerciseByNumber(to);
        final need = exerciseGear[to];
        final fits =
            !loadsProtectedArea(to, p.protectedAreas) &&
            (need == null || need.intersection(p.gear).isNotEmpty);
        if (!fits && k > 0) continue;
        if (to == i.exerciseNumber || e.number != to) return i;
        return i.isHold
            ? PlanItem.hold(to, i.sets, i.holdSeconds!, perSide: i.perSide)
            : PlanItem.reps(to, i.sets, i.reps!, perSide: i.perSide);
      }
      return i;
    }
    return i;
  }

  /// Stage a user starts a multi-stage plan at, from their level.
  int startingStage(PlanTemplate t, UserProfile p) => switch (p.level) {
    PlanLevel.beginner => 0,
    PlanLevel.intermediate => 1,
    PlanLevel.advanced => 2,
  }.clamp(0, t.stages.length - 1);

  /// Whether [week] (1-based) is a recovery week.
  bool isDeloadWeek(int week) => week % 4 == 0;

  /// Moves up a stage once a 4-week cycle is done with at least 75% of
  /// sessions completed; otherwise the user repeats the stage.
  int nextStage(
    PlanTemplate t,
    int stage, {
    required int sessionsDone,
    required int sessionsPlanned,
  }) {
    final ready = sessionsPlanned > 0 && sessionsDone / sessionsPlanned >= 0.75;
    return ready ? (stage + 1).clamp(0, t.stages.length - 1) : stage;
  }

  /// Builds week [week] (1-based) of the plan at [stageIndex].
  BuiltWeek buildWeek(
    PlanTemplate t,
    UserProfile p, {
    required int week,
    int? stageIndex,
    int skipLeadingDays = 0,
  }) {
    final stage =
        t.stages[(stageIndex ?? startingStage(t, p)).clamp(
          0,
          t.stages.length - 1,
        )];
    final stageIdx = t.stages.indexOf(stage);
    final deload = isDeloadWeek(week);
    final days = (_trainingDays[p.daysPerWeek.clamp(1, 6)])!;

    var next = 0;
    var skipLeft = skipLeadingDays;
    var skipped = skipLeadingDays <= 0;
    final planned = <PlannedDay>[];
    for (var weekday = 0; weekday < 7; weekday++) {
      if (days.contains(weekday) && skipLeadingDays > 0 && !skipped) {
        // A plan that starts mid-week: the days before it began get no
        // session, so the plan's first session lands on its first real day.
        skipLeft--;
        planned.add(PlannedDay(weekday: weekday));
        if (skipLeft == 0) skipped = true;
      } else if (days.contains(weekday)) {
        final session = stage.sessions[next % stage.sessions.length];
        // Weeks and repeats of the same session differ: the variant rotates
        // which exercises, accessories and drills it uses.
        final perWeek = _perWeek(days.length, stage.sessions.length, next);
        final variant = (week - 1) * perWeek + next ~/ stage.sessions.length;
        final position = next;
        next++;
        planned.add(
          PlannedDay(
            weekday: weekday,
            session: _buildSession(
              session,
              p,
              week,
              deload,
              variant: variant,
              position: position,
              mobility: t.focus == PlanFocus.mobility,
              levelShift: t.focus == PlanFocus.skill ? 0 : _levelSteps(p.level),
            ),
          ),
        );
      } else {
        planned.add(PlannedDay(weekday: weekday));
      }
    }
    return BuiltWeek(
      weekNumber: week,
      stageIndex: stageIdx,
      isDeload: deload,
      days: planned,
    );
  }

  BuiltSession _buildSession(
    PlanSession s,
    UserProfile p,
    int week,
    bool deload, {
    int variant = 0,
    int position = 0,
    int levelShift = 0,
    bool mobility = false,
  }) {
    final warmUp = _drills(
      _rotate(_warmUps[s.focus]!, variant),
      _warmUpCount,
      p,
    );
    final coolDown = _drills(
      _rotate(_coolDowns[s.focus]!, variant),
      _coolDownCount[s.focus]!,
      p,
    );
    // The player opens with a 10 s "first up", then every warm-up and
    // cool-down drill is 30 s with a rest after it.
    final dressingSeconds =
        _openingSeconds +
        (warmUp.length + coolDown.length) * (drillSeconds + _restSeconds);
    final minutes = p.sessionMinutes.clamp(10, 20);
    final budget = minutes * 60 - dressingSeconds;

    // +1 rep (or +5 s) per week within a cycle, up to +3 weeks; deload weeks
    // go back to base volume with one set fewer.
    final bump = deload ? 0 : ((week - 1) % 4).clamp(0, 3);

    // Level changes the volume: intermediate adds a set to the first two
    // exercises, advanced adds one to every exercise (up to 5 sets).
    int levelSets(PlanItem i) {
      final position = s.items.indexOf(i);
      return switch (p.level) {
        PlanLevel.beginner => 0,
        PlanLevel.intermediate => position >= 0 && position < 2 ? 1 : 0,
        PlanLevel.advanced => 1,
      };
    }

    BuiltItem build(PlanItem i) => BuiltItem(
      exerciseNumber: i.exerciseNumber,
      sets: (i.sets + levelSets(i)).clamp(1, 5),
      reps: i.reps == null ? null : i.reps! + bump,
      holdSeconds: i.holdSeconds == null ? null : i.holdSeconds! + bump * 5,
      perSide: i.perSide,
    );

    // Steer away from exercises that load an area she wants to protect.
    // Her level moves each exercise along its ladder (e.g. Wall -> Incline ->
    // Knee -> Standard Push-Up), and a rung that repeats another is dropped.
    final items = <BuiltItem>[];
    final seenVideos = <int>{};
    for (final raw in _rotateItems(s.items, variant)) {
      final i = _shiftItem(raw, levelShift, p);
      if (loadsProtectedArea(i.exerciseNumber, p.protectedAreas)) continue;
      if (!seenVideos.add(exerciseByNumber(i.exerciseNumber).videoNumber)) {
        continue;
      }
      items.add(build(i));
    }

    // Up to two exercises (one in a 10-minute session) aimed at her chosen focus areas, when they fit.
    final focusPicks = <PlanItem>[];
    for (final a in _accessories(
      s.focus,
      p,
      taken: items,
      focusOnly: true,
      levelShift: levelShift,
      variant: variant,
      mobility: mobility,
    )) {
      final v = exerciseByNumber(a.exerciseNumber).videoNumber;
      if (focusPicks.length < (minutes >= 15 ? 2 : 1) &&
          !focusPicks.any(
            (f) => exerciseByNumber(f.exerciseNumber).videoNumber == v,
          )) {
        focusPicks.add(a);
      }
    }
    final reserved = _seconds([for (final f in focusPicks) build(f)]);

    // Fit the time she chose: drop trailing plan items, but keep three.
    while (items.length > 3 && _seconds(items) + reserved > budget) {
      items.removeLast();
    }
    final cover = items.isEmpty ? null : items.first.exerciseNumber;
    final own = [for (final i in items) i.exerciseNumber];
    // Her focus exercises lead the session, so they are what she sees first.
    items.insertAll(0, [for (final f in focusPicks) build(f)]);

    // Short of the chosen time by 2+ minutes: top up (up to 6 more) with matching accessories.
    var added = 0;
    for (final a in _accessories(
      s.focus,
      p,
      taken: items,
      levelShift: levelShift,
      variant: variant,
      mobility: mobility,
    )) {
      if (added >= 6 || _seconds(items) >= budget - 45) break;
      final candidate = build(a);
      final video = exerciseByNumber(a.exerciseNumber).videoNumber;
      if (items.any(
        (i) => exerciseByNumber(i.exerciseNumber).videoNumber == video,
      )) {
        continue; // the candidate list was built before earlier top-ups
      }
      if (_seconds([...items, candidate]) > budget + 30) continue;
      items.add(candidate);
      added++;
    }

    // A session needs at least three exercises: when her avoid areas rule out
    // most of this plan's own, borrow suitable ones from the other pools.
    if (items.length < 3) {
      for (final pool in _rotate(
        (mobility ? _mobilitySessionPools : _sessionPools).values.toList(),
        variant + position,
      )) {
        for (final raw in _rotate(pool, variant + position)) {
          if (items.length >= 3) break;
          final i = _shiftItem(raw, levelShift, p);
          final video = exerciseByNumber(i.exerciseNumber).videoNumber;
          final ok =
              exerciseAllowedFor(exerciseByNumber(i.exerciseNumber), p) &&
              !items.any(
                (x) => exerciseByNumber(x.exerciseNumber).videoNumber == video,
              );
          if (ok) items.add(build(i));
        }
      }
    }

    // Over the chosen time even at three exercises: trim a set from the last
    // ones (never below two sets) until it fits.
    for (var k = items.length - 1; _seconds(items) > budget + 30 && k >= 0;) {
      final i = items[k];
      if (i.sets > 2) {
        items[k] = BuiltItem(
          exerciseNumber: i.exerciseNumber,
          sets: i.sets - 1,
          reps: i.reps,
          holdSeconds: i.holdSeconds,
          perSide: i.perSide,
        );
      } else {
        k--;
      }
    }

    // Still short with every suitable exercise used: add a set to the early
    // exercises, one at a time, until the chosen time is about right.
    var guard = 0;
    for (
      var k = 0;
      items.isNotEmpty && _seconds(items) < budget - 45 && guard < 40;
      guard++
    ) {
      final i = items[k % items.length];
      final more =
          i.sets < 6 && _seconds([...items, ..._oneSet(i)]) <= budget + 40;
      if (more) {
        items[k % items.length] = BuiltItem(
          exerciseNumber: i.exerciseNumber,
          sets: i.sets + 1,
          reps: i.reps,
          holdSeconds: i.holdSeconds,
          perSide: i.perSide,
        );
      }
      k++;
    }

    final total = _seconds(items) + dressingSeconds;
    return BuiltSession(
      name: s.name,
      warmUp: warmUp,
      items: items,
      coolDown: coolDown,
      estimatedMinutes: (total / 60).round(),
      coverNumber: cover,
      ownNumbers: own,
    );
  }

  /// Accessory exercises that suit [p] and aren't already in [taken], best
  /// matches for her focus areas first. With [focusOnly], only those.
  List<PlanItem> _accessories(
    PlanSessionFocus focus,
    UserProfile p, {
    required List<BuiltItem> taken,
    bool focusOnly = false,
    int levelShift = 0,
    int variant = 0,
    bool mobility = false,
  }) {
    final used = {
      for (final i in taken) exerciseByNumber(i.exerciseNumber).videoNumber,
    };
    bool ok(PlanItem i) {
      final e = exerciseByNumber(i.exerciseNumber);
      return !used.contains(e.videoNumber) && exerciseAllowedFor(e, p);
    }

    final focused = <PlanItem>[];
    for (final area in p.focusAreas) {
      final pools =
          (mobility ? _mobilityFocusPools : _focusPools)[area] ??
          const <List<PlanItem>>[];
      for (final pool in pools) {
        focused.addAll(pool.map((i) => _shiftItem(i, levelShift, p)).where(ok));
      }
    }
    final lead = _rotate(focused, variant);
    if (focusOnly) return lead;
    return [
      ...lead,
      ..._rotate(
        (mobility ? _mobilitySessionPools : _sessionPools)[focus]!,
        variant,
      ).map((i) => _shiftItem(i, levelShift, p)).where(ok),
      // Last resort when her level's rungs are all in use: easier versions
      // from the same pool.
      ...(mobility ? _mobilitySessionPools : _sessionPools)[focus]!.where(ok),
    ];
  }

  /// How many times the session at position [next] of a week is trained in
  /// that week (so its repeats across weeks get distinct variants).
  int _perWeek(int trainingDays, int sessions, int next) {
    final index = next % sessions;
    var count = 0;
    for (var n = 0; n < trainingDays; n++) {
      if (n % sessions == index) count++;
    }
    return count;
  }

  /// [list] started [by] places further along (wrapping around).
  List<T> _rotate<T>(List<T> list, int by) {
    if (list.isEmpty) return list;
    final k = by % list.length;
    return [...list.sublist(k), ...list.sublist(0, k)];
  }

  /// The first two exercises of a session stay (they are what the session is
  /// for); the rest rotate so each week trains a different mix.
  List<PlanItem> _rotateItems(List<PlanItem> items, int variant) {
    if (items.length <= 3) return items;
    return [...items.take(2), ..._rotate(items.skip(2).toList(), variant)];
  }

  /// A copy of [i] for costing one more set.
  List<BuiltItem> _oneSet(BuiltItem i) => [
    BuiltItem(
      exerciseNumber: i.exerciseNumber,
      sets: 1,
      reps: i.reps,
      holdSeconds: i.holdSeconds,
      perSide: i.perSide,
    ),
  ];

  int _seconds(List<BuiltItem> items) {
    var total = 0;
    for (final i in items) {
      // The player runs every set on a timer: rep exercises get a fixed set.
      final work = i.holdSeconds ?? drillSeconds;
      total += i.sets * (work * (i.perSide ? 2 : 1) + _restSeconds);
    }
    return total;
  }

  /// The full template library, for callers that need to look one up.
  PlanTemplate? templateById(String id) {
    for (final t in planTemplates) {
      if (t.id == id) return t;
    }
    return null;
  }
}
