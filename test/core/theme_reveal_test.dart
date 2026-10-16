import 'package:calisthenics/core/theme/theme_reveal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('without a host the theme change just applies', (t) async {
    var applied = false;
    await ThemeReveal.run(Offset.zero, () => applied = true);
    expect(applied, isTrue);
    expect(ThemeReveal.running.value, isFalse);
  });
}
