import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/features/plans/domain/plan_builder.dart';
import 'package:calisthenics/features/workout/domain/workout_request.dart';
import 'package:calisthenics/features/workout/presentation/providers/workout_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _request = WorkoutRequest(
  templateId: 'foundation-full-body',
  progressKey: 'k',
  session: BuiltSession(
    name: 'Quick',
    warmUp: [92],
    items: [],
    coolDown: [],
    estimatedMinutes: 1,
  ),
);

void main() {
  testWidgets('the countdown waits while the video loads', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    final sub = c.listen(workoutControllerProvider(_request), (_, _) {});
    final ctl = c.read(workoutControllerProvider(_request).notifier);
    final start = ctl.countdown.value;

    ctl.setVideoLoading(true);
    await t.pump(const Duration(seconds: 3));
    expect(ctl.countdown.value, start, reason: 'held while loading');

    ctl.setVideoLoading(false);
    await t.pump(const Duration(seconds: 2));
    expect(ctl.countdown.value, start - 2, reason: 'runs once it plays');

    // A load that never finishes cannot freeze the workout.
    ctl.setVideoLoading(true);
    await t.pump(const Duration(seconds: 14));
    expect(ctl.countdown.value, lessThan(start - 2));

    sub.close();
    c.dispose(); // stops the workout's ticking timer
  });
}
