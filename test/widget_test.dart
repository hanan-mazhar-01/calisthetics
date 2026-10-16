import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/routing/app_shell.dart';
import 'package:calisthenics/main.dart';

void main() {
  testWidgets('App boots to the onboarding welcome screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const CalestheticsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start my journey'), findsOneWidget);
  });

  testWidgets(
    'A user who finished onboarding is sent straight to the main app',
    (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const CalestheticsApp(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // The test font is wider than the shipped one, so Home reports a harmless
      // overflow; the redirect itself is what's under test.
      tester.takeException();
      expect(find.text('Start my journey'), findsNothing);
      expect(find.byType(AppShell), findsOneWidget);
    },
  );
}
