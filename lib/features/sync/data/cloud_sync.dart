import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps a signed-in user's data in Firestore (`users/{uid}`), so it comes
/// back on any phone she signs in on.
///
/// * Guest (not signed in): nothing leaves the phone.
/// * Signs in to an account that already has data: that data replaces
///   what is on the phone.
/// * Creates a new account (no data online yet): what is on the phone is
///   uploaded to it.
/// * While signed in: every change is saved online a few seconds later.
/// * Signs out: her data is removed from this phone (it stays online).
///
/// Everything the app stores under `user_*` and `onboarding_*` in shared
/// preferences is synced, as one document.
class CloudSync with WidgetsBindingObserver {
  CloudSync({
    required this.prefs,
    required this.onRestored,
    required this.onSignedOut,
    this.auth,
    this.firestore,
  });

  final SharedPreferences prefs;

  /// Called after an account's data replaced the local data (reload state).
  final Future<void> Function() onRestored;

  /// Called after sign-out wiped the local data (back to the start).
  final Future<void> Function() onSignedOut;

  FirebaseAuth? auth;
  FirebaseFirestore? firestore;

  FirebaseAuth? get _auth => auth;
  FirebaseFirestore? get _db => firestore;

  /// Tests switch this off so nothing touches Firebase.
  static bool enabled = true;

  /// The account whose data is on this phone right now.
  static const _ownerKey = 'sync_owner_uid';

  StreamSubscription<User?>? _authSub;
  Timer? _poll;
  Timer? _debounce;
  String? _lastPushed;
  bool _busy = false;

  static bool _synced(String key) =>
      key.startsWith('user_') || key.startsWith('onboarding_');

  void start() {
    if (!enabled) return;
    try {
      auth ??= FirebaseAuth.instance;
      firestore ??= FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Cloud sync unavailable: $e');
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _authSub = _auth!.authStateChanges().listen(_onAuth);
    // Cheap local check; only a real change is uploaded.
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _schedulePush());
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    _poll?.cancel();
    _debounce?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _push();
    } else if (state == AppLifecycleState.resumed) {
      pullFromRemote();
    }
  }

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db!.collection('users').doc(uid);

  Future<void> _onAuth(User? user) async {
    final owner = prefs.getString(_ownerKey);
    if (user == null) {
      if (owner != null) {
        // Signed out: her data leaves this phone (it is safe online).
        await _wipeLocal();
        await prefs.remove(_ownerKey);
        _lastPushed = null;
        await onSignedOut();
      }
      return;
    }
    if (owner == user.uid) return; // already this account's data
    _busy = true;
    try {
      final snap = await _doc(user.uid).get();
      final remote = snap.data()?['data'];
      if (remote is Map && remote.isNotEmpty) {
        // Existing account: merge any guest progress done on this device,
        // then write to local storage and refresh UI.
        final localData = _snapshot();
        final merged = _mergeRemoteWithLocal(
          Map<String, dynamic>.from(remote),
          localData,
        );
        await _wipeLocal();
        await _writeLocal(merged);
        await prefs.setString(_ownerKey, user.uid);
        _lastPushed = jsonEncode(_snapshot());
        await onRestored();

        // Push merged state back to cloud if guest data contributed to it
        _busy = false;
        await _push(force: true);
      } else {
        // New account: what she did as a guest becomes her account's data.
        await prefs.setString(_ownerKey, user.uid);
        _busy = false;
        await _push(force: true);
      }
    } catch (e) {
      debugPrint('Cloud sync sign-in failed: $e');
    } finally {
      _busy = false;
    }
  }

  /// Pulls latest changes from remote Firestore (e.g. on app resume).
  Future<void> pullFromRemote() async {
    final user = _auth?.currentUser;
    if (user == null || _busy) return;
    if (prefs.getString(_ownerKey) != user.uid) return;

    try {
      final snap = await _doc(user.uid).get();
      final remote = snap.data()?['data'];
      if (remote is Map && remote.isNotEmpty) {
        final remoteMap = Map<String, dynamic>.from(remote);
        final encodedRemote = jsonEncode(remoteMap);
        final encodedLocal = jsonEncode(_snapshot());
        if (encodedRemote != encodedLocal) {
          await _wipeLocal();
          await _writeLocal(remoteMap);
          _lastPushed = jsonEncode(_snapshot());
          await onRestored();
        }
      }
    } catch (e) {
      debugPrint('Cloud sync pull failed: $e');
    }
  }

  /// Manually triggers a debounced push.
  void schedulePush() => _schedulePush();

  /// Forces an immediate sync to Firestore.
  Future<void> syncNow() => _push(force: true);

  /// Wipes local account data on this device and resets state back to the welcome screen.
  Future<void> handleSignOut() async {
    await _wipeLocal();
    await prefs.remove(_ownerKey);
    _lastPushed = null;
    await onSignedOut();
  }

  void _schedulePush() {
    if (_busy || _auth?.currentUser == null) return;
    final now = jsonEncode(_snapshot());
    if (now == _lastPushed) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _push);
  }

  Future<void> _push({bool force = false}) async {
    final user = _auth?.currentUser;
    if (user == null || _busy) return;
    if (prefs.getString(_ownerKey) != user.uid) return;
    final data = _snapshot();
    final encoded = jsonEncode(data);
    if (!force && encoded == _lastPushed) return;
    try {
      await _doc(user.uid).set({
        'data': data,
        'updatedAt': FieldValue.serverTimestamp(),
        'email': user.email,
      });
      _lastPushed = encoded;
    } catch (e) {
      debugPrint('Cloud sync upload failed: $e');
    }
  }

  /// Deletes the signed-in account's online data (account deletion).
  Future<void> deleteRemote() async {
    final user = _auth?.currentUser;
    if (user == null) return;
    try {
      await _doc(user.uid).delete();
    } catch (e) {
      debugPrint('Cloud sync delete failed: $e');
    }
  }

  Map<String, dynamic> _snapshot() => {
    for (final k in prefs.getKeys())
      if (_synced(k)) k: prefs.get(k),
  };

  Future<void> _wipeLocal() async {
    for (final k in prefs.getKeys().toList()) {
      if (_synced(k)) await prefs.remove(k);
    }
  }

  Future<void> _writeLocal(Map<String, dynamic> data) async {
    for (final e in data.entries) {
      final v = e.value;
      if (v is bool) {
        await prefs.setBool(e.key, v);
      } else if (v is int) {
        await prefs.setInt(e.key, v);
      } else if (v is double) {
        await prefs.setDouble(e.key, v);
      } else if (v is num) {
        await prefs.setInt(e.key, v.toInt());
      } else if (v is String) {
        await prefs.setString(e.key, v);
      } else if (v is List) {
        await prefs.setStringList(e.key, [for (final x in v) '$x']);
      }
    }
  }

  /// Combines remote user data with any local guest sessions to prevent data loss.
  Map<String, dynamic> _mergeRemoteWithLocal(
    Map<String, dynamic> remote,
    Map<String, dynamic> local,
  ) {
    final merged = Map<String, dynamic>.from(remote);

    // Merge workout history
    if (local['user_history'] != null) {
      try {
        final remoteHistory =
            (jsonDecode(remote['user_history'] as String? ?? '[]') as List);
        final localHistory =
            (jsonDecode(local['user_history'] as String? ?? '[]') as List);
        final seen = <String>{};
        final combined = <dynamic>[];
        for (final item in [...remoteHistory, ...localHistory]) {
          if (item is Map) {
            final key = '${item['finishedAt']}_${item['sessionName']}';
            if (seen.add(key)) combined.add(item);
          }
        }
        merged['user_history'] = jsonEncode(combined);
      } catch (_) {}
    }

    // Merge favorites
    if (local['user_favorites'] != null) {
      try {
        final remoteFavs = List<String>.from(
          (remote['user_favorites'] as List?) ?? [],
        );
        final localFavs = List<String>.from(
          (local['user_favorites'] as List?) ?? [],
        );
        merged['user_favorites'] = {...remoteFavs, ...localFavs}.toList();
      } catch (_) {}
    }

    // Merge personal records (higher is better)
    if (local['user_records'] != null) {
      try {
        final remoteRec = Map<String, dynamic>.from(
          jsonDecode(remote['user_records'] as String? ?? '{}') as Map,
        );
        final localRec = Map<String, dynamic>.from(
          jsonDecode(local['user_records'] as String? ?? '{}') as Map,
        );
        for (final entry in localRec.entries) {
          final remoteVal = (remoteRec[entry.key] as num?)?.toInt() ?? 0;
          final localVal = (entry.value as num?)?.toInt() ?? 0;
          remoteRec[entry.key] = remoteVal > localVal ? remoteVal : localVal;
        }
        merged['user_records'] = jsonEncode(remoteRec);
      } catch (_) {}
    }

    // Merge plank history
    if (local['user_plank_history'] != null) {
      try {
        final remotePlanks =
            (jsonDecode(remote['user_plank_history'] as String? ?? '[]')
                as List);
        final localPlanks =
            (jsonDecode(local['user_plank_history'] as String? ?? '[]') as List);
        final seen = <String>{};
        final combined = <dynamic>[];
        for (final item in [...remotePlanks, ...localPlanks]) {
          if (item is Map) {
            final key = '${item['at']}_${item['seconds']}';
            if (seen.add(key)) combined.add(item);
          }
        }
        merged['user_plank_history'] = jsonEncode(combined);
      } catch (_) {}
    }

    // If remote has no plans but local has plans, keep local plans
    if ((remote['user_plans'] == null || remote['user_plans'] == '[]') &&
        local['user_plans'] != null &&
        local['user_plans'] != '[]') {
      merged['user_plans'] = local['user_plans'];
      if (local['user_current_plan'] != null) {
        merged['user_current_plan'] = local['user_current_plan'];
      }
    }

    return merged;
  }
}
