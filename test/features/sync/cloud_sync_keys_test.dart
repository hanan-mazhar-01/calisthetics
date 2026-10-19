import 'package:calisthenics/features/paywall/data/subscription_service.dart';
import 'package:calisthenics/features/sync/data/cloud_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the user\'s plan, history and answers go to the cloud copy', () {
    for (final key in [
      'user_active_plan',
      'user_settings',
      'onboarding_name',
      'onboarding_completed',
    ]) {
      expect(CloudSync.shared(key), isTrue, reason: key);
    }
  });

  test('the Premium status never does: the store is the only truth', () {
    expect(subscriptionPrefsKey, 'user_subscription');
    expect(CloudSync.shared(subscriptionPrefsKey), isFalse);
  });

  test('things that are not the user\'s data stay out', () {
    expect(CloudSync.shared('sync_last_pushed'), isFalse);
    expect(CloudSync.shared('flutter.something_else'), isFalse);
  });
}
