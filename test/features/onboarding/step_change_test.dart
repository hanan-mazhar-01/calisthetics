import 'dart:io';

import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's real fonts, so text is measured as on a phone (tests otherwise
/// draw in a much wider stand-in font).
Future<void> _loadAppFonts() async {
  for (final (family, files) in [
    (
      'Poppins',
      ['Poppins-Regular', 'Poppins-Medium', 'Poppins-SemiBold', 'Poppins-Bold'],
    ),
    ('Lora', ['Lora-Medium']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('assets/google_fonts/$f.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(_loadAppFonts);
  testWidgets('the old step is gone the moment the next one appears', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_schema_version': 3,
      'onboarding_index': 0,
    });
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const CalestheticsApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Start my journey'), findsOneWidget);

    await tester.tap(find.text('Start my journey'));
    // One frame later: no cross-fade is running, so nothing of the welcome
    // screen is left on screen under the next question.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Start my journey'), findsNothing);
    expect(find.textContaining('Already training with us'), findsNothing);

    // Let the next headline finish typing so no timer is left behind.
    await tester.pump(const Duration(seconds: 3));
  });
}
