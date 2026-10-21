import 'package:calisthenics/shared/widgets/google_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the path reader handles every command the logo uses', () {
    for (final (_, d) in googleLogoPaths) {
      final bounds = parseSvgPath(d).getBounds();
      // All four pieces sit inside Google's 48 x 48 box.
      expect(bounds.left, greaterThanOrEqualTo(-0.01));
      expect(bounds.top, greaterThanOrEqualTo(-0.01));
      expect(bounds.right, lessThanOrEqualTo(48.01));
      expect(bounds.bottom, lessThanOrEqualTo(48.01));
      expect(bounds.width, greaterThan(5));
    }
    final square = parseSvgPath('M0 0h10v10H0z').getBounds();
    expect(square, const Rect.fromLTRB(0, 0, 10, 10));
  });

  test('the logo has Google\'s four colours', () {
    expect(
      {for (final (c, _) in googleLogoPaths) c.toARGB32()},
      {
        0xFFEA4335, // red
        0xFF4285F4, // blue
        0xFFFBBC05, // yellow
        0xFF34A853, // green
      },
    );
  });

  testWidgets('it draws at any size and says "Google" to screen readers', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: GoogleLogo(size: 30)),
      ),
    );
    expect(tester.getSize(find.byType(GoogleLogo)), const Size(30, 30));
    expect(find.bySemanticsLabel('Google'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
