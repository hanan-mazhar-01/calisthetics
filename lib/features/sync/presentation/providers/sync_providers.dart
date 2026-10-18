import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/shared_preferences_provider.dart';
import '../../../auth/domain/auth_failure.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../onboarding/presentation/providers/onboarding_completed_provider.dart';
import '../../../onboarding/presentation/providers/onboarding_controller.dart';
import '../../../paywall/presentation/providers/subscription_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../data/cloud_sync.dart';

/// Provider for [CloudSync].
/// When user is signed in, syncs data between Firestore `users/{uid}` and local storage.
/// When user is a guest, leaves data completely offline with 0 network calls.
final cloudSyncProvider = Provider<CloudSync>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);

  void refreshAll() {
    ref.invalidate(ownedPlansProvider);
    ref.invalidate(currentPlanIdProvider);
    ref.invalidate(activePlanProvider);
    ref.invalidate(historyProvider);
    ref.invalidate(favoritesProvider);
    ref.invalidate(recordsProvider);
    ref.invalidate(plankHistoryProvider);
    ref.invalidate(partialProgressProvider);
    ref.invalidate(partialLogProvider);
    ref.invalidate(settingsProvider);
    ref.invalidate(onboardingControllerProvider);
    ref.invalidate(onboardingCompletedProvider);
    ref.invalidate(subscriptionProvider);
  }

  final sync = CloudSync(
    prefs: prefs,
    onRestored: () async => refreshAll(),
    onSignedOut: () async => refreshAll(),
  );

  sync.start();

  // Schedule an immediate debounced push whenever local user state mutates
  ref.listen(ownedPlansProvider, (_, _) => sync.schedulePush());
  ref.listen(currentPlanIdProvider, (_, _) => sync.schedulePush());
  ref.listen(historyProvider, (_, _) => sync.schedulePush());
  ref.listen(favoritesProvider, (_, _) => sync.schedulePush());
  ref.listen(recordsProvider, (_, _) => sync.schedulePush());
  ref.listen(plankHistoryProvider, (_, _) => sync.schedulePush());
  ref.listen(partialProgressProvider, (_, _) => sync.schedulePush());
  ref.listen(partialLogProvider, (_, _) => sync.schedulePush());
  ref.listen(settingsProvider, (_, _) => sync.schedulePush());
  ref.listen(onboardingControllerProvider, (_, _) => sync.schedulePush());
  ref.listen(subscriptionProvider, (_, _) => sync.schedulePush());

  ref.onDispose(sync.dispose);

  return sync;
});

/// Sign-in, sign-out and account deletion, so every screen runs them the
/// same way and the data on the phone always belongs to the right person.
class AccountSession {
  const AccountSession(this._ref);
  final Ref _ref;

  CloudSync get _sync => _ref.read(cloudSyncProvider);

  /// After a successful sign-in or sign-up: waits until the account's data
  /// (existing account) or the guest's data (new account) is in place.
  /// Returns whether onboarding is finished, i.e. the app should go home.
  Future<bool> afterSignIn() async {
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      await _sync.adopt(user);
      await _ref.read(subscriptionProvider.notifier).setAccount(user.uid);
    }
    return _ref.read(onboardingCompletedProvider);
  }

  /// Saves anything not online yet, signs out, and clears this phone. The
  /// account's data stays online for the next sign-in.
  Future<void> signOut() async {
    await _sync.syncNow();
    await _ref.read(authControllerProvider.notifier).signOut();
    await _sync.handleSignOut();
    await _ref.read(subscriptionProvider.notifier).setAccount(null);
  }

  /// Deletes the account everywhere: the Firestore document, the Firebase
  /// user, and everything this app stored on the phone. Throws
  /// [AuthFailure] if it was cancelled or failed before anything was
  /// deleted.
  Future<void> deleteAccount({
    required Future<String?> Function() askPassword,
  }) async {
    final repo = _ref.read(authRepositoryProvider);
    if (repo.currentUser != null) {
      var dataDeleted = false;
      try {
        await repo.deleteAccount(
          askPassword: askPassword,
          deleteData: () async {
            await _sync.deleteRemote();
            dataDeleted = true;
          },
        );
      } on AuthFailure {
        // Online data is already gone: finish locally and sign out anyway.
        if (!dataDeleted) rethrow;
        await repo.signOut();
      }
      await _sync.finishDelete();
    }
    await _ref.read(accountActionsProvider).deleteLocalData();
    await _ref.read(subscriptionProvider.notifier).setAccount(null);
  }
}

final accountSessionProvider = Provider<AccountSession>(AccountSession.new);
