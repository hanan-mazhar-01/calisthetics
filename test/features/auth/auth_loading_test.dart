import 'dart:async';

import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/auth/presentation/providers/auth_providers.dart';
import 'package:calisthenics/features/auth/presentation/widgets/auth_modal_sheet.dart';
import 'package:calisthenics/shared/widgets/dots_loader.dart';
import 'package:calisthenics/shared/widgets/primary_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Google sign-in that waits until the test lets it finish.
class _SlowAuth extends AuthController {
  final done = Completer<void>();
  @override
  Future<UserCredential?> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
    await done.future;
    state = state.copyWith(isLoading: false);
    return null;
  }
}

void main() {
  testWidgets('only the tapped sign-in button shows the loader', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = _SlowAuth();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(() => auth),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: AuthModalSheet()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(DotsLoader), findsNothing);

    await tester.tap(find.text('Continue with Google'));
    await tester.pump(const Duration(milliseconds: 300));
    // One loader, on Google's button; the other button keeps its label and look.
    expect(find.byType(DotsLoader), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Email'), findsOneWidget);
    final email = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue with Email'),
    );
    expect(email.onPressed, isNull); // taps are ignored meanwhile...
    expect(
      email.style!.backgroundColor!.resolve({WidgetState.disabled}),
      email.style!.backgroundColor!.resolve({}),
    ); // ...but it is not dimmed

    auth.done.complete();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(DotsLoader), findsNothing);
  });

  testWidgets('a loading PrimaryButton keeps its colour and shows the dots', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: PrimaryButton(label: 'Sign In', loading: true, onPressed: null),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DotsLoader), findsOneWidget);
    expect(find.text('Sign In'), findsNothing);
    final box = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect((box.decoration as BoxDecoration).color!.a, 1.0);
  });

  testWidgets('the dots stand still when animations are off', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: DotsLoader(color: Colors.black)),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(DotsLoader), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
