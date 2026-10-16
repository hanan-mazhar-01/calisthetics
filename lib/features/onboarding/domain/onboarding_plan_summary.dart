import '../../exercises/domain/exercise_lookup.dart';
import '../../plans/data/plan_templates.dart';
import '../../plans/domain/plan_builder.dart';
import '../../plans/domain/plan_recommender.dart';
import '../../plans/domain/plan_template.dart';
import '../../plans/domain/user_profile.dart';
import '../../../shared/models/calisthenics_skill.dart';
import 'onboarding_step.dart';
import 'skill_abilities.dart';

/// Selection keys the plan-selection and ability steps own.
const planChoiceKey = 'plan-choice';
const abilityKey = 'skill-ability';

const _gearNames = {
  PlanGear.pullUpBar: 'Pull-up bar',
  PlanGear.parallelBars: 'Parallettes or dip bars',
  PlanGear.wall: 'Wall',
  PlanGear.band: 'Resistance band',
  PlanGear.chair: 'Sturdy chair or box',
};

const _areaNames = {
  ProtectedArea.wrists: 'Wrists',
  ProtectedArea.shoulders: 'Shoulders',
  ProtectedArea.lowerBack: 'Lower back',
  ProtectedArea.knees: 'Knees',
  ProtectedArea.neck: 'Neck',
};

String protectedAreaLabel(ProtectedArea a) => _areaNames[a]!;

/// Equipment a plan uses, in plain words ("No equipment" when it needs none).
String planEquipmentLabel(PlanTemplate t) {
  if (t.gear.isEmpty) return 'No equipment';
  return [
    for (final g in PlanGear.values)
      if (t.gear.contains(g)) _gearNames[g],
  ].join(', ');
}

/// Short warning for plans that need a bar the user doesn't have, else null.
String? missingGearTag(Set<PlanGear> missing) {
  if (missing.isEmpty) return null;
  if (missing.contains(PlanGear.pullUpBar)) return 'Needs a pull-up bar';
  return 'Needs parallettes or dip bars';
}

String protectedConflictLabel(Set<ProtectedArea> conflicts) =>
    'Not suitable for: ${[for (final a in conflicts) _areaNames[a]!.toLowerCase()].join(', ')}';

/// Selections with the answers that depend on the chosen plan removed, so the
/// recommendation never changes because of an earlier plan choice.
Map<String, Set<String>> selectionsForRecommendation(
  Map<String, Set<String>> selections,
) => {
  for (final e in selections.entries)
    if (e.key != planChoiceKey && e.key != abilityKey) e.key: e.value,
};

/// Ranked plans for the user, from the same engine the app uses afterwards.
List<PlanRecommendation> recommendationsFor(
  Map<String, Set<String>> selections, {
  int? plankSeconds,
}) => const PlanRecommender().recommend(
  UserProfile.fromSelections(
    selectionsForRecommendation(selections),
    plankSeconds: plankSeconds,
  ),
);

/// The "best for you" pick: the top plan she can do today, or, when none
/// qualifies, the top plan that needs no missing gear.
PlanRecommendation heroRecommendation(List<PlanRecommendation> recs) {
  for (final r in recs) {
    if (r.bestForYou) return r;
  }
  for (final r in recs) {
    if (r.missingGear.isEmpty) return r;
  }
  return recs.first;
}

CalisthenicsSkill? skillOf(PlanTemplate t) {
  for (final s in calisthenicsSkills) {
    if (s.id == t.skillId) return s;
  }
  return null;
}

const _firstStep = {
  'push-up': 'a first knee push-up',
  'pull-up': 'a first negative pull-up',
  'chin-up': 'a first negative chin-up',
  'dips': 'a first band-assisted dip',
  'handstand': 'a steady wall walk',
  'l-sit': 'a steady tuck support hold',
  'pistol-squat': 'a first box pistol squat',
  'toes-to-bar': 'controlled hanging knee raises',
};

const _plainNames = {'l-sit': 'L-sit'};

/// Real figures for the plan the user picked, derived by [PlanBuilder] from
/// her answers. Every plan-specific onboarding screen reads from here.
class OnboardingPlanSummary {
  OnboardingPlanSummary._({
    required this.template,
    required this.profile,
    required this.weeks,
    required this.startStage,
    required this.ability,
    required this.start,
  });

  final PlanTemplate template;
  final UserProfile profile;

  /// The first four-week cycle.
  final List<BuiltWeek> weeks;
  final int startStage;
  final SkillAbility? ability;
  final DateTime start;

  static OnboardingPlanSummary? from(
    Map<String, Set<String>> selections, {
    int? plankSeconds,
    required DateTime today,
  }) {
    final id = (selections[planChoiceKey] ?? const {}).firstOrNull;
    PlanTemplate? template;
    for (final t in planTemplates) {
      if (t.id == id) template = t;
    }
    if (template == null) return null;
    final profile = UserProfile.fromSelections(
      selections,
      plankSeconds: plankSeconds,
    );
    const builder = PlanBuilder();
    final startStage = builder.startingStage(template, profile);
    return OnboardingPlanSummary._(
      template: template,
      profile: profile,
      weeks: [
        for (var w = 1; w <= 4; w++)
          builder.buildWeek(template, profile, week: w, stageIndex: startStage),
      ],
      startStage: startStage,
      ability: abilityById(
        template.skillId,
        (selections[abilityKey] ?? const {}).firstOrNull,
      ),
      start: DateTime(today.year, today.month, today.day),
    );
  }

  CalisthenicsSkill? get skill => skillOf(template);

  List<PlannedDay> get _trainingDays => [
    for (final d in weeks.first.days)
      if (!d.isRest) d,
  ];

  int get sessionsPerWeek => _trainingDays.length;

  String get minutesLabel {
    final minutes = [
      for (final d in _trainingDays) d.session!.estimatedMinutes,
    ];
    if (minutes.isEmpty) return '-';
    minutes.sort();
    return minutes.first == minutes.last
        ? '${minutes.first} min'
        : '${minutes.first}–${minutes.last} min';
  }

  String get equipmentLabel => planEquipmentLabel(template);

  String get stageName => template.stages[startStage].name;

  /// Exercise she starts from (skill plans only).
  String? get startingExercise {
    final n = ability?.exerciseNumber;
    return n == null ? null : exerciseByNumber(n).name;
  }

  List<String> get protectedLabels => [
    for (final a in ProtectedArea.values)
      if (profile.protectedAreas.contains(a)) _areaNames[a]!,
  ];

  /// What a first 28-day cycle can honestly aim at, e.g. "a first negative
  /// pull-up". Never a promise: the copy around it says "aim for".
  String get outcome {
    final s = skill;
    if (s == null) {
      final what = switch (template.focus) {
        PlanFocus.fullBody => 'full-body',
        PlanFocus.core => 'core',
        PlanFocus.legsGlutes => 'legs and glutes',
        PlanFocus.conditioning => 'conditioning',
        PlanFocus.mobility => 'mobility',
        PlanFocus.skill => 'skill',
      };
      return 'a steady $what routine you can keep';
    }
    final plain = _plainNames[s.id] ?? s.label.toLowerCase();
    return switch (startStage) {
      0 => _firstStep[s.id] ?? 'your first step on the $plain ladder',
      1 => 'progress toward a full $plain',
      _ => 'harder $plain variations',
    };
  }

  /// Length of the first cycle, from the weeks the plan builder laid out.
  int get cycleDays => weeks.length * 7;

  DateTime get targetDate => start.add(Duration(days: cycleDays));

  String get targetDateLabel =>
      '${_months[targetDate.month - 1]} ${targetDate.day}';

  List<CalendarDay> get calendar => [
    for (final d in weeks.first.days)
      CalendarDay(label: _weekdays[d.weekday], isTraining: !d.isRest),
  ];

  /// Share of the week's sessions that train each area, read from the
  /// exercises the plan builder really chose (so a focus area or an avoided
  /// joint shows up here too). A session counts for every area it touches.
  List<MuscleAllocation> get allocations {
    var upper = 0, lower = 0, core = 0;
    final n = sessionsPerWeek;
    for (final day in _trainingDays) {
      final areas = <_Area>{
        for (final item in day.session!.items) ..._areasOf(item.exerciseNumber),
      };
      if (areas.contains(_Area.upper)) upper++;
      if (areas.contains(_Area.lower)) lower++;
      if (areas.contains(_Area.core)) core++;
    }
    MuscleAllocation share(String label, int count) => MuscleAllocation(
      label: '$label · $count of $n sessions',
      fraction: n == 0 ? 0 : count / n,
    );
    return [
      share('Upper body', upper),
      share('Core', core),
      share('Legs & glutes', lower),
      MuscleAllocation(
        label: 'Warm-up & cool-down · every session',
        fraction: 1,
      ),
    ];
  }

  /// Four phases: the weeks of the first cycle, as [PlanBuilder] builds them.
  List<ProgramPhase> get phases {
    const names = ['Base', 'A little more', 'A little more', 'Recovery'];
    return [
      for (var i = 0; i < weeks.length; i++)
        () {
          final sessions = [
            for (final d in weeks[i].days)
              if (!d.isRest) d.session!,
          ];
          final session = sessions.isEmpty
              ? null
              : sessions[i % sessions.length];
          return ProgramPhase(
            number: '0${i + 1}',
            label: names[i],
            weekRange:
                'Days ${i * 7 + 1}–${i * 7 + 7}${session == null ? '' : ' · ${session.name}'}',
            exercises: [
              if (session != null)
                for (final item in session.items.take(4))
                  exerciseByNumber(item.exerciseNumber).name,
            ],
            sessionName: session?.name ?? '',
            exerciseNumbers: [
              if (session != null)
                for (final item in session.items.take(4)) item.exerciseNumber,
            ],
            targets: [
              if (session != null)
                for (final item in session.items.take(4))
                  // Every set runs on a timer in the player (30 s unless
                  // it is a longer hold).
                  '${item.holdSeconds ?? PlanBuilder.drillSeconds}s',
            ],
          );
        }(),
    ];
  }

  /// A few exercise names from the first session, for the loading screen.
  List<String> get previewExercises {
    final first = _trainingDays.firstOrNull?.session;
    if (first == null) return const [];
    return [
      for (final item in first.items.take(6))
        exerciseByNumber(item.exerciseNumber).name,
    ];
  }

  List<int> get previewNumbers {
    final first = _trainingDays.firstOrNull?.session;
    if (first == null) return const [];
    return [for (final item in first.items.take(6)) item.exerciseNumber];
  }

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

enum _Area { upper, core, lower }

/// Which body areas an exercise trains, from the 115-exercise guide's own
/// sections (mixed-in conditioning, mobility and extras are listed by number).
Set<_Area> _areasOf(int number) {
  const mixed = <int, Set<_Area>>{
    28: {_Area.core, _Area.upper},
    29: {_Area.lower},
    30: {_Area.upper, _Area.core, _Area.lower},
    25: {_Area.lower},
    26: {_Area.lower, _Area.upper},
    27: {_Area.lower, _Area.upper},
    101: {_Area.upper, _Area.lower},
    113: {_Area.upper, _Area.core, _Area.lower},
    114: {_Area.lower, _Area.core},
    115: {_Area.core},
  };
  final hit = mixed[number];
  if (hit != null) return hit;
  return switch (exerciseByNumber(number).sectionId) {
    'foundation-upper' ||
    'skill-push-up' ||
    'skill-pull-up' ||
    'skill-dips' ||
    'skill-chin-up' ||
    'skill-handstand' => {_Area.upper},
    'foundation-core' || 'skill-l-sit' || 'skill-toes-to-bar' => {_Area.core},
    'foundation-legs' || 'skill-pistol-squat' => {_Area.lower},
    'extras' =>
      number >= 106 && number <= 109 || number == 111
          ? {_Area.upper}
          : {_Area.lower},
    _ => const {},
  };
}
