import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/legal/presentation/screens/legal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (kind, title, section) in [
    (
      LegalKind.privacy,
      'Privacy Policy',
      '5. User Rights, Data Control & Account Deletion',
    ),
    (LegalKind.terms, 'Terms of Use', '5. Subscriptions, Free Trial & Billing'),
    (LegalKind.support, 'Help & Support', '3. Premium and Subscriptions'),
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
      // A long text: a section further down shows once scrolled to.
      await tester.scrollUntilVisible(
        find.text(section),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(section), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Support Email'),
        600,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('support@veradostudio.com'), findsWidgets);
    });
  }

  testWidgets('Help & Support opens with an email button and the questions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const LegalScreen(kind: LegalKind.support),
      ),
    );
    expect(find.bySemanticsLabel('Email support@veradostudio.com'), findsOne);
    expect(find.text('1. Getting Started'), findsOneWidget);
    // A question is a bold sub-heading of its own, not part of the answer.
    final question = tester.widget<Text>(find.text('Why is a day locked?'));
    expect(question.style?.fontWeight, FontWeight.w600);
    expect(find.textContaining('## '), findsNothing);
    // The other two documents do not carry the button.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const LegalScreen(kind: LegalKind.privacy),
      ),
    );
    expect(
      find.bySemanticsLabel('Email support@veradostudio.com'),
      findsNothing,
    );
  });
}
