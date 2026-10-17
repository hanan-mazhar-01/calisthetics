/// Human-readable failure representations for Firebase Authentication.
class AuthFailure {
  const AuthFailure(this.message);

  final String message;

  factory AuthFailure.fromCode(String code, [String? fallbackMessage]) {
    switch (code) {
      case 'invalid-email':
        return const AuthFailure('The email address is not valid.');
      case 'user-disabled':
        return const AuthFailure('This account has been disabled.');
      case 'user-not-found':
        return const AuthFailure('No account found for this email.');
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthFailure('Incorrect email or password.');
      case 'email-already-in-use':
        return const AuthFailure(
          'An account already exists with this email. Try signing in instead.',
        );
      case 'operation-not-allowed':
        return const AuthFailure(
          'This sign-in method is not enabled. Please contact support.',
        );
      case 'weak-password':
        return const AuthFailure(
          'Password should be at least 6 characters long.',
        );
      case 'network-request-failed':
        return const AuthFailure(
          'Network connection error. Please check your internet connection.',
        );
      case 'too-many-requests':
        return const AuthFailure(
          'Too many failed attempts. Please try again in a few minutes.',
        );
      case 'sign_in_canceled':
      case 'canceled':
      case '12501': // Google Sign In canceled
        return const AuthFailure('Sign in was canceled.');
      default:
        return AuthFailure(fallbackMessage ?? 'Authentication failed. Please try again.');
    }
  }

  @override
  String toString() => message;
}
