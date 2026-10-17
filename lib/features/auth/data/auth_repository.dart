import 'dart:convert' show utf8;
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../domain/auth_failure.dart';

/// Repository for handling all Firebase Authentication operations:
/// - Email & Password (Sign In, Sign Up, Password Reset)
/// - Google Sign-In (Cross-platform)
/// - Apple Sign-In (iOS Native & Android/Web OAuth)
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance {
    _initGoogleSignIn();
  }

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  // Server Web Client ID from google-services.json for OAuth token exchange
  static const String _serverClientId =
      '6017591128-t5fhqdqlbt2b9l55mmmbjtilpabnsrn4.apps.googleusercontent.com';

  bool _googleInitialized = false;

  void _initGoogleSignIn() {
    if (!kIsWeb && !_googleInitialized) {
      _googleSignIn.initialize(
        serverClientId: _serverClientId,
      );
      _googleInitialized = true;
    }
  }

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed in user, if any.
  User? get currentUser => _auth.currentUser;

  /// Whether a user is currently authenticated.
  bool get isAuthenticated => _auth.currentUser != null;

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
      throw AuthFailure('Google sign-in error: ${e.description ?? e.code.name}');
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
      final isApplePlatform = defaultTargetPlatform == TargetPlatform.iOS ||
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

        final OAuthCredential credential = OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
        );

        final userCredential = await _auth.signInWithCredential(credential);

        if (appleCredential.givenName != null || appleCredential.familyName != null) {
          final fullName = [appleCredential.givenName, appleCredential.familyName]
              .where((s) => s != null && s.isNotEmpty)
              .join(' ');
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
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    await _auth.signOut();
  }

  /// Helper to generate cryptographically secure nonce for Apple Sign In.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = math.Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }
}
