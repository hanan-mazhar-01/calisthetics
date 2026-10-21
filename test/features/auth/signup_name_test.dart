import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/auth/presentation/providers/auth_providers.dart';
import 'package:calisthenics/features/auth/presentation/widgets/auth_modal_sheet.dart';
import 'package:calisthenics/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Credential implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Sign-up that always works, remembering the name it was given.
class _FakeAuth extends AuthController {
  String? gotName;
  @override
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    gotName = displayName;
    return _Credential();
  }
}

void main() {
  testWidgets('the name typed at sign-up replaces the onboarding name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'onboarding_name': 'Hanan'});
    final prefs = await SharedPreferences.getInstance();
    final auth = _FakeAuth();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authControllerProvider.overrideWith(() => auth),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: AuthModalSheet(initialIsSignUp: true)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Sign up with Email'));
    await tester.pump(const Duration(milliseconds: 500));

    // The field starts with the name from onboarding.
    final nameField = find.widgetWithText(TextFormField, 'Hanan');
    expect(nameField, findsOneWidget);

    await tester.enterText(nameField, 'Ali');
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'ali@example.com');
    await tester.enterText(fields.at(2), 'secret123');
    await tester.tap(find.text('Create Account'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(auth.gotName, 'Ali');
    expect(container.read(onboardingControllerProvider).name, 'Ali');
  });
}
