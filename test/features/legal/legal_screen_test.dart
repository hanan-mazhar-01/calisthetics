import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/legal/presentation/screens/legal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (kind, title, section) in [
    (LegalKind.privacy, 'Privacy Policy', 'Delete your data'),
    (LegalKind.terms, 'Terms of Use', 'Billing and renewal'),
  ]) {
    testWidgets('$title shows its sections', (tester) async {
      tester.view.physicalSize = const Size(900, 6000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: LegalScreen(kind: kind),
        ),
      );
      expect(find.text(title), findsOneWidget);
      expect(find.text(section), findsOneWidget);
      expect(find.textContaining('support@veradostudio.com'), findsWidgets);
    });
  }
}
