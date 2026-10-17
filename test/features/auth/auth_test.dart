import 'package:flutter_test/flutter_test.dart';

import 'package:calisthenics/features/auth/domain/auth_failure.dart';
import 'package:calisthenics/features/auth/presentation/providers/auth_providers.dart';

void main() {
  group('AuthFailure tests', () {
    test('maps common firebase codes correctly', () {
      expect(
        AuthFailure.fromCode('user-not-found').message,
        'No account found for this email.',
      );
      expect(
        AuthFailure.fromCode('wrong-password').message,
        'Incorrect email or password.',
      );
      expect(
        AuthFailure.fromCode('email-already-in-use').message,
        'An account already exists with this email. Try signing in instead.',
      );
      expect(
        AuthFailure.fromCode('weak-password').message,
        'Password should be at least 6 characters long.',
      );
      expect(
        AuthFailure.fromCode('sign_in_canceled').message,
        'Sign in was canceled.',
      );
    });

    test('falls back to custom message for unknown code', () {
      expect(
        AuthFailure.fromCode('unknown-error', 'Custom fallback').message,
        'Custom fallback',
      );
    });
  });

  group('AuthState tests', () {
    test('default state has isLoading false and no error', () {
      const state = AuthState();
      expect(state.isLoading, false);
      expect(state.errorMessage, null);
    });

    test('copyWith updates state correctly', () {
      const state = AuthState();
      final updated = state.copyWith(
        isLoading: true,
        errorMessage: 'Something went wrong',
      );
      expect(updated.isLoading, true);
      expect(updated.errorMessage, 'Something went wrong');

      final cleared = updated.copyWith(clearError: true);
      expect(cleared.errorMessage, null);
    });
  });
}

