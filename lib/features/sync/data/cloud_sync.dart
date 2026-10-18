import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps a signed-in user's data in Firestore (`users/{uid}`), so it comes
/// back on any phone they sign in on.
///
/// * Guest (not signed in): nothing leaves the phone.
/// * Signs in to an account that already has data: that account's data
///   replaces what is on the phone (plans, answers, history, settings).
/// * Creates a new account (no data online yet): what they did as a guest
///   is uploaded and becomes the account's data.
/// * While signed in: every change is saved online a few seconds later.
/// * Signs out: their data is removed from this phone (it stays online).
/// * Deletes the account: the online document is deleted too.
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

  /// The last state that reached Firestore, so a change made offline (or
  /// just before the app was closed) is never overwritten by older online
  /// data.
  static const _pushedKey = 'sync_last_pushed';

  StreamSubscription<User?>? _authSub;
  Timer? _poll;
  Timer? _debounce;
  bool _busy = false;
  bool _started = false;

  Future<void>? _adopting;
  String? _adoptingUid;

  static bool _synced(String key) =>
      key.startsWith('user_') || key.startsWith('onboarding_');

  String? get _lastPushed => prefs.getString(_pushedKey);

  void start() {
    if (!enabled || _started) return;
    try {
      auth ??= FirebaseAuth.instance;
      firestore ??= FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Cloud sync unavailable: $e');
      return;
    }
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _authSub = _auth!.authStateChanges().listen(_onAuth);
    // Cheap local check; only a real change is uploaded.
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _schedulePush());
  }

  void dispose() {
    if (!_started) return;
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
    if (user == null) {
      if (prefs.getString(_ownerKey) != null) {
        // Signed out: their data leaves this phone (it is safe online).
        await _forget();
        await onSignedOut();
      }
      return;
    }
    await adopt(user);
  }

  /// Makes [user]'s account the owner of the data on this phone: restores
  /// the account's online data, or uploads the guest data to a new account.
  /// Safe to call more than once; callers await it after signing in, so
  /// they know which data is on the phone before they navigate.
  Future<void> adopt(User user) {
    if (!_started) return Future.value();
    if (prefs.getString(_ownerKey) == user.uid) return Future.value();
    if (_adopting != null && _adoptingUid == user.uid) return _adopting!;
    _adoptingUid = user.uid;
    return _adopting = _adopt(user).whenComplete(() {
      _adopting = null;
      _adoptingUid = null;
    });
  }

  Future<void> _adopt(User user) async {
    _busy = true;
    _debounce?.cancel();
    try {
      // Always ask the server: an empty offline cache must never be taken
      // for "new account" (that would overwrite their online data).
      final snap = await _doc(
        user.uid,
      ).get(const GetOptions(source: Source.server));
      final remote = snap.data()?['data'];
      if (remote is Map && remote.isNotEmpty) {
        // Existing account: its data is what they see on this phone.
        final data = Map<String, dynamic>.from(remote);
        await _wipeLocal();
        await _writeLocal(data);
        await prefs.setString(_ownerKey, user.uid);
        await prefs.setString(_pushedKey, jsonEncode(_snapshot()));
        await onRestored();
      } else {
        // New account: what they did as a guest becomes the account's data.
        await prefs.setString(_ownerKey, user.uid);
        _busy = false;
        await _push(force: true);
      }
    } catch (e) {
      // Offline or refused: try again on the next resume.
      debugPrint('Cloud sync sign-in failed: $e');
    } finally {
      _busy = false;
    }
  }

  /// On app resume: brings in changes made on another phone. Local changes
  /// that have not reached Firestore yet win and are uploaded instead.
  Future<void> pullFromRemote() async {
    final user = _auth?.currentUser;
    if (user == null || _busy) return;
    if (prefs.getString(_ownerKey) != user.uid) {
      await adopt(user);
      return;
    }
    final local = jsonEncode(_snapshot());
    if (local != _lastPushed) {
      await _push();
      return;
    }
    try {
      final snap = await _doc(
        user.uid,
      ).get(const GetOptions(source: Source.server));
      final remote = snap.data()?['data'];
      if (remote is! Map || remote.isEmpty) return;
      // Something changed here while we waited: keep it.
      if (_busy || jsonEncode(_snapshot()) != local) return;
      final remoteMap = Map<String, dynamic>.from(remote);
      await _wipeLocal();
      await _writeLocal(remoteMap);
      final now = jsonEncode(_snapshot());
      await prefs.setString(_pushedKey, now);
      if (now != local) await onRestored();
    } catch (e) {
      debugPrint('Cloud sync pull failed: $e');
    }
  }

  /// Manually triggers a debounced push.
  void schedulePush() => _schedulePush();

  /// Uploads anything not saved online yet (before signing out).
  Future<void> syncNow() async {
    _debounce?.cancel();
    await _push();
  }

  /// Removes the account's data from this phone (it stays online) and
  /// resets the app to the start. Idempotent.
  Future<void> handleSignOut() async {
    await _forget();
    await onSignedOut();
  }

  /// Account deletion, step 1: stops syncing and deletes the online
  /// document. Throws if it could not be deleted, so the caller can stop
  /// before anything else is lost.
  Future<void> deleteRemote() async {
    final user = _auth?.currentUser;
    if (user == null) return;
    _busy = true;
    _debounce?.cancel();
    try {
      await _doc(user.uid).delete();
    } catch (e) {
      _busy = false;
      rethrow;
    }
  }

  /// Account deletion, last step: syncing may run again (as a guest).
  Future<void> finishDelete() async {
    await prefs.remove(_ownerKey);
    await prefs.remove(_pushedKey);
    _busy = false;
  }

  Future<void> _forget() async {
    _debounce?.cancel();
    await _wipeLocal();
    await prefs.remove(_ownerKey);
    await prefs.remove(_pushedKey);
  }

  void _schedulePush() {
    if (_busy || _auth?.currentUser == null) return;
    if (jsonEncode(_snapshot()) == _lastPushed) return;
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
      await prefs.setString(_pushedKey, encoded);
    } catch (e) {
      debugPrint('Cloud sync upload failed: $e');
    }
  }

  /// Keys sorted, so the same data always encodes to the same string.
  Map<String, dynamic> _snapshot() => {
    for (final k in prefs.getKeys().where(_synced).toList()..sort())
      k: prefs.get(k),
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
}
