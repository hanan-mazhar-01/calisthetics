import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/plans/domain/plan_builder.dart';
import 'package:calisthenics/features/workout/domain/workout_request.dart';
import 'package:calisthenics/features/workout/presentation/providers/workout_controller.dart';
import 'package:calisthenics/features/workout/presentation/screens/workout_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // App Store Review 2.5.4: leaving the app mid-workout must not keep the
  // timer, video and music running; coming back loses nothing.
  testWidgets('leaving the app pauses the workout; nothing is lost', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    const request = WorkoutRequest(
      templateId: 'daily',
      session: BuiltSession(
        name: 'Background',
        warmUp: [],
        items: [BuiltItem(exerciseNumber: 1, sets: 1, holdSeconds: 30)],
        coolDown: [],
        estimatedMinutes: 2,
      ),
    );
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const WorkoutScreen(request: request),
        ),
      ),
    );
    await t.tap(find.text('Skip'));
    await t.pump(const Duration(milliseconds: 400));
    final before = c.read(workoutControllerProvider(request));
    expect(before.paused, isFalse);

    // Home button: resumed -> inactive -> hidden -> paused.
    for (final s in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      t.binding.handleAppLifecycleStateChanged(s);
    }
    await t.pump();
    final away = c.read(workoutControllerProvider(request));
    expect(away.paused, isTrue);

    // Time passes while away: the workout does not move on.
    await t.pump(const Duration(seconds: 5));
    final later = c.read(workoutControllerProvider(request));
    expect(later.index, away.index);
    expect(later.phase, away.phase);

    // Back in the app: same place, still paused until the user taps Play.
    for (final s in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      t.binding.handleAppLifecycleStateChanged(s);
    }
    await t.pump();
    final back = c.read(workoutControllerProvider(request));
    expect(back.paused, isTrue);
    expect(back.index, before.index);
  });
}
