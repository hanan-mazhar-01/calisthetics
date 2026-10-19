import 'package:calisthenics/features/legal/domain/legal_links.dart';
import 'package:calisthenics/features/legal/domain/legal_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'only a real https address opens on the web; anything else falls back',
    () {
      expect(webAddress(''), isNull);
      expect(webAddress('   '), isNull);
      expect(webAddress('privacy-policy.html'), isNull);
      expect(webAddress('http://example.com/privacy'), isNull);
      expect(webAddress('javascript:alert(1)'), isNull);
      expect(webAddress('https://'), isNull);
      expect(
        webAddress(' https://calesthetics.blogspot.com/p/privacy.html '),
        Uri.parse('https://calesthetics.blogspot.com/p/privacy.html'),
      );
    },
  );

  test('until the pages are published the app shows its own text', () {
    // When the two web addresses are filled in, this test is the reminder
    // that the in-app fallback is still there for offline use.
    expect(privacySections, isNotEmpty);
    expect(termsSections, isNotEmpty);
  });

  test('the in-app text matches the pages: same contact, prices and date', () {
    final privacy = privacySections
        .map((s) => '${s.heading}\n${s.body}')
        .join();
    final terms = termsSections.map((s) => '${s.heading}\n${s.body}').join();
    for (final text in [privacy, terms]) {
      expect(text, contains('support@veradostudio.com'));
    }
    expect(terms, contains(r'$9.99'));
    expect(terms, contains(r'$49.99'));
    expect(terms, contains('7-day free trial'));
    expect(privacy, contains('Profile > Delete Account'));
    // Guests have no account to delete: both texts name the button they see.
    expect(privacy, contains('Profile > Erase data on this phone'));
    expect(terms, contains('Profile > Erase data on this phone'));
    expect(legalUpdated, 'October 19, 2026');
  });
}
