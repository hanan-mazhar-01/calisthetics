import 'package:calisthenics/features/onboarding/presentation/widgets/typewriter_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: child),
  ),
);

String _shownText(WidgetTester t) {
  final rich = t.widget<RichText>(find.byType(RichText).first);
  final buf = StringBuffer();
  rich.text.visitChildren((s) {
    if (s is TextSpan &&
        s.text != null &&
        s.style?.color != Colors.transparent) {
      buf.write(s.text);
    }
    return true;
  });
  return buf.toString();
}

void main() {
  testWidgets('types the headline out, then reports done', (t) async {
    var done = 0;
    await t.pumpWidget(
      _host(
        TypewriterText(
          style: const TextStyle(fontSize: 20),
          segments: const [TypeSegment('How '), TypeSegment('old')],
          onDone: () => done++,
        ),
      ),
    );
    expect(_shownText(t), isEmpty);
    await t.pump(const Duration(milliseconds: 400));
    final partial = _shownText(t);
    expect(partial.length, inInclusiveRange(1, 6));
    await t.pump(const Duration(seconds: 2));
    expect(_shownText(t), 'How old');
    expect(done, 1);
  });

  testWidgets('with reduce-motion the full text shows at once', (t) async {
    var done = 0;
    await t.pumpWidget(
      _host(
        reduceMotion: true,
        TypewriterText(
          style: const TextStyle(fontSize: 20),
          segments: const [TypeSegment('Hello there')],
          onDone: () => done++,
        ),
      ),
    );
    await t.pump();
    expect(_shownText(t), 'Hello there');
    expect(done, 1);
  });
}
