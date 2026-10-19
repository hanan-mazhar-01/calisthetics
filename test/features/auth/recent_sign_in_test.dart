import 'package:calisthenics/features/auth/domain/recent_sign_in.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 19, 15, 0);

  test('a sign-in made a moment ago is recent: no second confirmation', () {
    expect(
      signInIsRecent(now.subtract(const Duration(seconds: 20)), now),
      isTrue,
    );
    expect(
      signInIsRecent(now.subtract(const Duration(minutes: 2)), now),
      isTrue,
    );
  });

  test('an older sign-in is not recent: the user must confirm', () {
    expect(signInIsRecent(now.subtract(recentSignInWindow), now), isFalse);
    expect(
      signInIsRecent(now.subtract(const Duration(minutes: 10)), now),
      isFalse,
    );
    expect(signInIsRecent(now.subtract(const Duration(days: 3)), now), isFalse);
  });

  test('an unknown sign-in time is never recent', () {
    expect(signInIsRecent(null, now), isFalse);
  });

  test('the window stays under what Firebase accepts', () {
    // The server accepted 4 minutes and refused 5: stay under 4.
    expect(recentSignInWindow, lessThan(const Duration(minutes: 4)));
  });
}
