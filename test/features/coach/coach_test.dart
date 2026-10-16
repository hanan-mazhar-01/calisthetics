import 'package:calisthenics/features/coach/domain/coach_message.dart';
import 'package:calisthenics/features/coach/domain/coach_quota.dart';
import 'package:calisthenics/features/coach/domain/coach_repository.dart';
import 'package:calisthenics/features/coach/domain/coach_suggestions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final oct = DateTime(2026, 10, 12);
  final nov = DateTime(2026, 11, 1);

  test('quota counts down, blocks free users at the limit, not premium', () {
    var q = CoachQuota.empty(oct);
    expect(q.remaining(oct), freeMonthlyCoachMessages);
    for (var i = 0; i < freeMonthlyCoachMessages; i++) {
      expect(q.canSend(oct, isPremium: false), isTrue);
      q = q.recordSend(oct);
    }
    expect(q.remaining(oct), 0);
    expect(q.canSend(oct, isPremium: false), isFalse);
    expect(q.canSend(oct, isPremium: true), isTrue);
  });

  test('a new month resets usage', () {
    final q = CoachQuota(monthKey: '2026-10', used: 10);
    expect(q.canSend(nov, isPremium: false), isTrue);
    expect(q.recordSend(nov).used, 1);
    expect(q.recordSend(nov).monthKey, '2026-11');
  });

  test('json round trip and bad data', () {
    final q = CoachQuota(monthKey: '2026-10', used: 3);
    expect(CoachQuota.fromJson(q.toJson(), oct).used, 3);
    expect(CoachQuota.fromJson('junk', oct).used, 0);
  });

  test('default repository never fabricates a reply', () {
    const repo = UnavailableCoachRepository();
    expect(repo.isAvailable, isFalse);
    expect(
      repo.send(const [CoachMessage(CoachRole.user, 'hi')], 'hello'),
      throwsA(isA<CoachUnavailable>()),
    );
  });

  test('starters exist without a plan', () {
    expect(coachStarters(null), isNotEmpty);
  });
}
