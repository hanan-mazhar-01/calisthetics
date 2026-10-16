import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/active_plan.dart';
import '../domain/completed_session.dart';
import '../domain/partial_effort.dart';
import '../domain/plank_attempt.dart';

/// Local persistence for everything the user does after onboarding. Works
/// fully offline; a later sync layer mirrors it to the cloud.
class UserDataStore {
  const UserDataStore(this._prefs);

  final SharedPreferences _prefs;

  static const _planKey = 'user_active_plan'; // legacy single plan
  static const _plansKey = 'user_plans';
  static const _currentPlanKey = 'user_current_plan';
  static const _historyKey = 'user_history';
  static const _favoritesKey = 'user_favorites';
  static const _recordsKey = 'user_records';
  static const _settingsKey = 'user_settings';
  static const _plankKey = 'user_plank_history';
  static const _partialKey = 'user_partial_progress';
  static const _partialLogKey = 'user_partial_log';

  /// Every plan the user has added. Older installs stored a single plan under
  /// a different key; it is picked up here as the first (and only) plan.
  List<ActivePlan> readPlans() {
    final raw = _prefs.getString(_plansKey);
    if (raw != null) {
      return [
        for (final j in jsonDecode(raw) as List)
          ActivePlan.fromJson(j as Map<String, dynamic>),
      ];
    }
    final legacy = _prefs.getString(_planKey);
    return legacy == null
        ? []
        : [ActivePlan.fromJson(jsonDecode(legacy) as Map<String, dynamic>)];
  }

  Future<void> writePlans(List<ActivePlan> plans) async {
    await _prefs.remove(_planKey);
    await _prefs.setString(
      _plansKey,
      jsonEncode([for (final p in plans) p.toJson()]),
    );
  }

  /// Template id of the plan the user is currently following, or null.
  String? readCurrentPlanId() => _prefs.getString(_currentPlanKey);

  Future<void> writeCurrentPlanId(String? id) => id == null
      ? _prefs.remove(_currentPlanKey)
      : _prefs.setString(_currentPlanKey, id);

  List<CompletedSession> readHistory() {
    final raw = _prefs.getString(_historyKey);
    if (raw == null) return [];
    return [
      for (final j in jsonDecode(raw) as List)
        CompletedSession.fromJson(j as Map<String, dynamic>),
    ];
  }

  Future<void> writeHistory(List<CompletedSession> history) => _prefs.setString(
    _historyKey,
    jsonEncode([for (final s in history) s.toJson()]),
  );

  Set<int> readFavorites() => {
    ...(_prefs.getStringList(_favoritesKey) ?? const []).map(int.parse),
  };

  Future<void> writeFavorites(Set<int> numbers) =>
      _prefs.setStringList(_favoritesKey, [for (final n in numbers) '$n']);

  /// Personal records by key, e.g. `plankSeconds`.
  Map<String, int> readRecords() {
    final raw = _prefs.getString(_recordsKey);
    return raw == null
        ? {}
        : (jsonDecode(raw) as Map<String, dynamic>).cast<String, int>();
  }

  Future<void> writeRecords(Map<String, int> records) =>
      _prefs.setString(_recordsKey, jsonEncode(records));

  List<PlankAttempt> readPlankHistory() {
    final raw = _prefs.getString(_plankKey);
    if (raw == null) return [];
    return [
      for (final j in jsonDecode(raw) as List)
        PlankAttempt.fromJson(j as Map<String, dynamic>),
    ];
  }

  Future<void> writePlankHistory(List<PlankAttempt> attempts) => _prefs
      .setString(_plankKey, jsonEncode([for (final a in attempts) a.toJson()]));

  /// How far she got in workouts she quit without marking complete, by day
  /// key, as a whole percent.
  Map<String, int> readPartialProgress() {
    final raw = _prefs.getString(_partialKey);
    return raw == null
        ? {}
        : (jsonDecode(raw) as Map<String, dynamic>).cast<String, int>();
  }

  Future<void> writePartialProgress(Map<String, int> progress) =>
      _prefs.setString(_partialKey, jsonEncode(progress));

  List<PartialEffort> readPartialLog() {
    final raw = _prefs.getString(_partialLogKey);
    if (raw == null) return [];
    return [
      for (final j in jsonDecode(raw) as List)
        PartialEffort.fromJson(j as Map<String, dynamic>),
    ];
  }

  Future<void> writePartialLog(List<PartialEffort> log) => _prefs.setString(
    _partialLogKey,
    jsonEncode([for (final e in log) e.toJson()]),
  );

  /// Free-form app settings (reminder time, voice cues, rest seconds…).
  Map<String, dynamic> readSettings() {
    final raw = _prefs.getString(_settingsKey);
    return raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> writeSettings(Map<String, dynamic> settings) =>
      _prefs.setString(_settingsKey, jsonEncode(settings));

  /// Wipes all user data (used by "Retake assessment" and account deletion).
  Future<void> clear() async {
    for (final k in [
      _planKey,
      _plansKey,
      _currentPlanKey,
      _historyKey,
      _favoritesKey,
      _recordsKey,
      _settingsKey,
      _plankKey,
      _partialKey,
      _partialLogKey,
    ]) {
      await _prefs.remove(k);
    }
  }
}
