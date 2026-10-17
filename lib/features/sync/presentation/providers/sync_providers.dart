import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/shared_preferences_provider.dart';
import '../../../onboarding/presentation/providers/onboarding_completed_provider.dart';
import '../../../onboarding/presentation/providers/onboarding_controller.dart';
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

  ref.onDispose(sync.dispose);

  return sync;
});
