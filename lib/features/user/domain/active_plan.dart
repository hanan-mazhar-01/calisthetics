import '../../plans/domain/user_profile.dart';
import 'completed_session.dart';

/// The plan the user is following: which template, when it began, which
/// stage they are on, and the profile it was built for.
class ActivePlan {
  const ActivePlan({
    required this.templateId,
    required this.startDate,
    required this.profile,
    this.stageIndex = 0,
    this.cyclesApplied = 0,
    this.progressFrom,
  });

  final String templateId;

  /// Date-only (local midnight).
  final DateTime startDate;
  final UserProfile profile;
  final int stageIndex;

  /// The moment the plan was started or last restarted. Only workouts finished
  /// from then on count towards this plan's days, so "Restart from Day 1"
  /// really begins again. Older saved plans fall back to [startDate].
  final DateTime? progressFrom;

  DateTime get countsFrom => progressFrom ?? startDate;

  /// Whether [s] is a workout of this plan that counts towards its progress.
  bool counts(CompletedSession s) =>
      s.templateId == templateId && !s.finishedAt.isBefore(countsFrom);

  /// How many completed 4-week cycles have already been judged for stage advancement.
  final int cyclesApplied;

  /// 1-based plan week containing [date]. Weeks run Monday–Sunday and week 1
  /// is the one containing [startDate], matching how plan weeks are scheduled.
  int weekNumberOn(DateTime date) {
    DateTime monday(DateTime d) => DateTime(
      d.year,
      d.month,
      d.day,
    ).subtract(Duration(days: d.weekday - 1));
    final days = monday(date).difference(monday(startDate)).inDays;
    return (days < 0 ? 0 : days) ~/ 7 + 1;
  }

  ActivePlan copyWith({
    int? stageIndex,
    int? cyclesApplied,
    UserProfile? profile,
  }) => ActivePlan(
    templateId: templateId,
    startDate: startDate,
    profile: profile ?? this.profile,
    stageIndex: stageIndex ?? this.stageIndex,
    cyclesApplied: cyclesApplied ?? this.cyclesApplied,
    progressFrom: progressFrom,
  );

  Map<String, dynamic> toJson() => {
    'templateId': templateId,
    'startDate': startDate.toIso8601String(),
    'profile': profile.toJson(),
    'stageIndex': stageIndex,
    'cyclesApplied': cyclesApplied,
    if (progressFrom != null) 'progressFrom': progressFrom!.toIso8601String(),
  };

  factory ActivePlan.fromJson(Map<String, dynamic> j) => ActivePlan(
    templateId: j['templateId'] as String,
    startDate: DateTime.parse(j['startDate'] as String),
    profile: UserProfile.fromJson(j['profile'] as Map<String, dynamic>),
    stageIndex: (j['stageIndex'] as int?) ?? 0,
    cyclesApplied: (j['cyclesApplied'] as int?) ?? 0,
    progressFrom: j['progressFrom'] == null
        ? null
        : DateTime.parse(j['progressFrom'] as String),
  );
}
