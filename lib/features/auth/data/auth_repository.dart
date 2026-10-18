import 'dart:convert' show utf8;
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../firebase_options.dart';
import '../domain/auth_failure.dart';

/// Repository for handling all Firebase Authentication operations:
/// - Email & Password (Sign In, Sign Up, Password Reset)
/// - Google Sign-In (Cross-platform)
/// - Apple Sign-In (iOS Native & Android/Web OAuth)
class AuthRepository {
  AuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _authOverride = auth,
      _googleOverride = googleSignIn;

  final FirebaseAuth? _authOverride;
  final GoogleSignIn? _googleOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn => _googleOverride ?? GoogleSignIn.instance;

  /// False until Firebase is set up (and in widget tests): everyone is a
  /// guest then.
  bool get _ready => _authOverride != null || Firebase.apps.isNotEmpty;

  // Server Web Client ID from google-services.json for OAuth token exchange
  static const String _serverClientId =
      '6017591128-t5fhqdqlbt2b9l55mmmbjtilpabnsrn4.apps.googleusercontent.com';

  bool _googleInitialized = false;

  void _initGoogleSignIn() {
    if (!kIsWeb && !_googleInitialized) {
      // iPhone needs the iOS client ID too (Android reads it from
      // google-services.json).
      final isIos = defaultTargetPlatform == TargetPlatform.iOS;
      _googleSignIn.initialize(
        clientId: isIos ? DefaultFirebaseOptions.ios.iosClientId : null,
        serverClientId: _serverClientId,
      );
      _googleInitialized = true;
    }
  }

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges =>
      _ready ? _auth.authStateChanges() : Stream.value(null);

  /// Currently signed in user, if any.
  User? get currentUser => _ready ? _auth.currentUser : null;

  /// Whether a user is currently authenticated.
  bool get isAuthenticated => currentUser != null;

  /// Sign in using Email and Password.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code, e.message);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  /// Create a new account using Email and Password.
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName != null && displayName.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code, e.message);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code, e.message);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  /// Interactive Google Sign-In.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider provider = GoogleAuthProvider();
        return await _auth.signInWithPopup(provider);
      }

      _initGoogleSignIn();
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication authentication = account.authentication;
      final String? idToken = authentication.idToken;

      if (idToken == null) {
        throw const AuthFailure('Failed to obtain Google ID token.');
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw AuthFailure(
        'Google sign-in error: ${e.description ?? e.code.name}',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code, e.message);
    } catch (e) {
      if (e.toString().contains('canceled') || e.toString().contains('12501')) {
        return null;
      }
      throw AuthFailure('Google sign-in failed: $e');
    }
  }

  /// Interactive Apple Sign-In.
  /// Uses native Apple Authorization on iOS/macOS, and Firebase OAuth provider on other platforms.
  Future<UserCredential?> signInWithApple() async {
    try {
      final isApplePlatform =
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS;

      if (isApplePlatform) {
        final rawNonce = _generateNonce();
        final shaNonce = sha256.convert(utf8.encode(rawNonce)).toString();

        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: shaNonce,
        );

        final OAuthCredential credential = OAuthProvider('apple.com')
            .credential(
              idToken: appleCredential.identityToken,
              rawNonce: rawNonce,
            );

        final userCredential = await _auth.signInWithCredential(credential);

        if (appleCredential.givenName != null ||
            appleCredential.familyName != null) {
          final fullName = [
            appleCredential.givenName,
            appleCredential.familyName,
          ].where((s) => s != null && s.isNotEmpty).join(' ');
          if (fullName.isNotEmpty && userCredential.user != null) {
            await userCredential.user!.updateDisplayName(fullName);
          }
        }

        return userCredential;
      } else {
        // Android or Web: Use Firebase OAuth Provider for Apple Sign-in
        final appleProvider = OAuthProvider('apple.com')
          ..addScope('email')
          ..addScope('name');
        return await _auth.signInWithProvider(appleProvider);
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      throw AuthFailure('Apple sign-in error: ${e.message}');
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code, e.message);
    } catch (e) {
      if (e.toString().contains('canceled')) {
        return null;
      }
      throw AuthFailure('Apple sign-in failed: $e');
    }
  }

  /// Sign out from all providers.
  Future<void> signOut() async {
    if (!_ready) return;
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    await _auth.signOut();
  }

  /// Deletes the signed-in Firebase user. The user first confirms who they
  /// are with their provider (Google, Apple) or password ([askPassword]),
  /// since Firebase only deletes a fresh sign-in; on iPhone this also
  /// revokes the app's Sign in with Apple token, as the App Store requires.
  /// [deleteData] runs after that and before the user is deleted, while
  /// Firestore still lets them delete their own document. If anything up
  /// to and including [deleteData] fails, nothing has been deleted.
  Future<void> deleteAccount({
    required Future<String?> Function() askPassword,
    required Future<void> Function() deleteData,
  }) async {
    final user = currentUser;
    if (user == null) return;
    final providers = {for (final p in user.providerData) p.providerId};
    try {
      await _reauthenticate(user, providers, askPassword);
      await deleteData();
      await user.delete();
      try {
        if (!kIsWeb) await _googleSignIn.signOut();
      } catch (_) {}
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code, e.message);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthFailure('Account deletion was cancelled.');
      }
      throw AuthFailure('Apple sign-in error: ${e.message}');
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure('Account deletion was cancelled.');
      }
      throw AuthFailure(
        'Google sign-in error: ${e.description ?? e.code.name}',
      );
    } catch (e) {
      throw AuthFailure('Could not delete the account: $e');
    }
  }

  Future<void> _reauthenticate(
    User user,
    Set<String> providers,
    Future<String?> Function() askPassword,
  ) async {
    if (providers.contains('google.com') && !kIsWeb) {
      _initGoogleSignIn();
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure('Failed to obtain Google ID token.');
      }
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } else if (providers.contains('apple.com')) {
      final isApplePlatform =
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS;
      if (isApplePlatform && !kIsWeb) {
        final rawNonce = _generateNonce();
        final apple = await SignInWithApple.getAppleIDCredential(
          scopes: const [],
          nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
        );
        await user.reauthenticateWithCredential(
          OAuthProvider('apple.com')
              .credential(idToken: apple.identityToken, rawNonce: rawNonce),
        );
        // Sign in with Apple stops trusting the app for this account.
        try {
          await _auth.revokeTokenWithAuthorizationCode(apple.authorizationCode);
        } catch (e) {
          debugPrint('Apple token revoke failed: $e');
        }
      } else {
        await user.reauthenticateWithProvider(OAuthProvider('apple.com'));
      }
    } else if (providers.contains('password') && user.email != null) {
      final password = await askPassword();
      if (password == null || password.isEmpty) {
        throw const AuthFailure('Account deletion was cancelled.');
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
    } else {
      throw const AuthFailure(
        'Please sign out, sign in again, then delete your account.',
      );
    }
  }

  /// Helper to generate cryptographically secure nonce for Apple Sign In.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = math.Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
