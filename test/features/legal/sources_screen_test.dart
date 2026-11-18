import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/legal/presentation/screens/sources_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('every source is a public https link with a stated use', () {
    expect(trainingSources, isNotEmpty);
    for (final s in trainingSources) {
      final uri = Uri.parse(s.url);
      expect(uri.scheme, 'https', reason: s.title);
      expect(uri.host, isNotEmpty, reason: s.title);
      expect(s.usedFor.trim(), isNotEmpty, reason: s.title);
    }
  });

  for (final size in const [Size(320, 568), Size(430, 932)]) {
    testWidgets('Sources & methodology lays out at $size', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const SourcesScreen()),
      );
      expect(find.text('Sources & methodology'), findsOneWidget);
      expect(find.text('How your plan is built'), findsOneWidget);
      await t.scrollUntilVisible(
        find.text(trainingSources.last.title),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(t.takeException(), isNull);
    });
  }
}
