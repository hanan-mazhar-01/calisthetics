import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/shared_preferences_provider.dart';

const onboardingCompletedKey = 'onboarding_completed';

final onboardingCompletedProvider =
    NotifierProvider<OnboardingCompletedNotifier, bool>(
      OnboardingCompletedNotifier.new,
    );

/// Whether the user has finished onboarding. The router redirect reads this:
/// finished users always land in the main app, unfinished users resume
/// onboarding from their saved step.
class OnboardingCompletedNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(onboardingCompletedKey) ??
      false;

  Future<void> complete() async {
    state = true;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(onboardingCompletedKey, true);
  }
}
