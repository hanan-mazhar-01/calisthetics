import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/auth/domain/apple_sign_in.dart';
import 'package:calisthenics/features/auth/presentation/widgets/auth_modal_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _openSheet(WidgetTester tester, TargetPlatform platform) async {
  debugDefaultTargetPlatformOverride = platform;
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: AuthModalSheet()),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('Sign in with Apple is for Apple devices only', () {
    test('iPhone, iPad and Mac get it', () {
      expect(appleSignInAvailableOn(TargetPlatform.iOS), isTrue);
      expect(appleSignInAvailableOn(TargetPlatform.macOS), isTrue);
    });

    test('Android, desktop Linux/Windows and the web do not', () {
      expect(appleSignInAvailableOn(TargetPlatform.android), isFalse);
      expect(appleSignInAvailableOn(TargetPlatform.linux), isFalse);
      expect(appleSignInAvailableOn(TargetPlatform.windows), isFalse);
      expect(appleSignInAvailableOn(TargetPlatform.iOS, web: true), isFalse);
    });

    testWidgets('Android: sign-in sheet has Google and email, no Apple', (
      tester,
    ) async {
      try {
        await _openSheet(tester, TargetPlatform.android);
        expect(find.text('Continue with Apple'), findsNothing);
        expect(find.text('Continue with Google'), findsOneWidget);
        expect(find.text('Continue with Email'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('iPhone: sign-in sheet has Apple first', (tester) async {
      try {
        await _openSheet(tester, TargetPlatform.iOS);
        expect(find.text('Continue with Apple'), findsOneWidget);
        expect(find.text('Continue with Google'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('Continue with Apple')).dy,
          lessThan(tester.getTopLeft(find.text('Continue with Google')).dy),
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
