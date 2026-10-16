import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/paywall/domain/paywall_offer.dart';
import 'package:calisthenics/features/paywall/presentation/screens/paywall_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(900, 2200);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(theme: AppTheme.light, home: const PaywallScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  test('offers are unavailable until subscriptions are connected', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final offers = container.read(paywallOffersProvider);
    expect(offers.isAvailable, isFalse);
    expect(offers.offers, isEmpty);
  });

  testWidgets('shows the honest empty state, no prices, disabled purchase', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      find.text('Prices will appear here once subscriptions are connected.'),
      findsOneWidget,
    );
    expect(find.textContaining(RegExp(r'[\$€£]\s?\d')), findsNothing);
    expect(find.text('Start free trial'), findsOneWidget);
    expect(find.text('Restore Purchases'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.textContaining('No ads'), findsNothing);
    expect(find.text('Switch plans any time'), findsOneWidget);
  });
}
