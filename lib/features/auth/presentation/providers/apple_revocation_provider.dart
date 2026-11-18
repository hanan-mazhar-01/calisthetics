import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../sync/presentation/providers/sync_providers.dart';
import '../../domain/apple_sign_in.dart';
import 'auth_providers.dart';

/// Signs the user out when they stop using Sign in with Apple for this app
/// (iOS Settings > Apple ID > Sign in with Apple > Stop Using), as Apple
/// requires. Checked at launch and every time the app comes back to the
/// foreground. Accounts made with Google or email are never touched, and a
/// failed check (no network, Apple not answering) changes nothing.
final appleRevocationProvider = Provider<void>((ref) {
  if (!appleSignInAvailable) return;

  var checking = false;
  Future<void> check() async {
    if (checking) return;
    final user = ref.read(authRepositoryProvider).currentUser;
    final apple = user?.providerData
        .where((p) => p.providerId == 'apple.com')
        .firstOrNull;
    final appleId = apple?.uid;
    if (appleId == null || appleId.isEmpty) return;
    checking = true;
    try {
      final state = await SignInWithApple.getCredentialState(appleId);
      if (state == CredentialState.revoked ||
          state == CredentialState.notFound) {
        await ref.read(accountSessionProvider).signOut();
      }
    } catch (e) {
      debugPrint('Apple credential check failed: $e');
    } finally {
      checking = false;
    }
  }

  final listener = AppLifecycleListener(onResume: check);
  ref.onDispose(listener.dispose);
  Future.microtask(check);
});
