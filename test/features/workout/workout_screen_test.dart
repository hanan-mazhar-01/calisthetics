import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/coach/presentation/screens/coach_screen.dart';
import 'package:calisthenics/features/plans/domain/plan_builder.dart';
import 'package:calisthenics/features/user/presentation/providers/user_providers.dart';
import 'package:calisthenics/features/workout/domain/workout_request.dart';
import 'package:calisthenics/features/workout/presentation/screens/workout_screen.dart';
import 'package:calisthenics/features/exercises/domain/exercise_lookup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> pump(WidgetTester t, Widget home) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.light, home: home),
    ),
  );
  return container;
}

void main() {
  testWidgets('runs a one-exercise session and saves it to history', (t) async {
    const request = WorkoutRequest(
      templateId: 'daily',
      session: BuiltSession(
        name: 'Quick one',
        warmUp: [],
        items: [BuiltItem(exerciseNumber: 1, sets: 1, reps: 8)],
        coolDown: [],
        estimatedMinutes: 2,
      ),
    );
    final container = await pump(t, const WorkoutScreen(request: request));
    expect(find.text('FIRST UP'), findsOneWidget);
    await t.tap(find.text('Skip'));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.byTooltip('Next'));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('How did that feel?'), findsOneWidget);
    await t.tap(find.text('Easy'));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('WORKOUT COMPLETE'), findsOneWidget);
    final history = container.read(historyProvider);
    expect(history.single.efforts.values.single.name, 'easy');
    expect(container.read(userStatsProvider).currentStreak, 1);
  });

  testWidgets('walks warm-up, main set, cool-down in order', (t) async {
    t.view.physicalSize = const Size(800, 1600);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    const request = WorkoutRequest(
      templateId: 'daily',
      session: BuiltSession(
        name: 'Order',
        warmUp: [90],
        items: [BuiltItem(exerciseNumber: 1, sets: 1, reps: 8)],
        coolDown: [95],
        estimatedMinutes: 2,
      ),
    );
    final container = await pump(t, const WorkoutScreen(request: request));
    Future<void> tick() async {
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      await t.pump();
    }

    String name(int n) => exerciseByNumber(n).name;

    expect(find.text('FIRST UP'), findsOneWidget);
    expect(find.text(name(90)), findsWidgets);
    expect(find.text('Step 1/3'), findsOneWidget);
    await t.tap(find.text('Skip'));
    await tick();
    // Warm-up drill is running: timed, so pause + next are in the capsule.
    expect(find.text(name(90)), findsWidgets);
    expect(find.byTooltip('Pause'), findsOneWidget);
    await t.tap(find.byTooltip('Next'));
    await tick();
    // "First up" announces the main exercise before it starts.
    expect(find.text('FIRST UP'), findsOneWidget);
    expect(find.text(name(1)), findsWidgets);
    await t.tap(find.text('Skip'));
    await tick();
    expect(find.byTooltip('Pause'), findsOneWidget); // timed 30 s set
    await t.tap(find.byTooltip('Next'));
    await tick();
    await t.tap(find.text('Hard'));
    await tick();
    expect(find.text('FIRST UP'), findsOneWidget);
    expect(find.text(name(95)), findsWidgets);
    await t.tap(find.text('Skip'));
    await tick();
    expect(find.text(name(95)), findsWidgets);
    await t.tap(find.byTooltip('Next'));
    await tick();
    expect(find.text('WORKOUT COMPLETE'), findsOneWidget);
    expect(container.read(historyProvider).single.exerciseNumbers, [1]);
  });

  testWidgets('tapping +10s adds ten seconds to the first-up countdown', (
    t,
  ) async {
    t.view.physicalSize = const Size(800, 1600);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    const request = WorkoutRequest(
      templateId: 'daily',
      session: BuiltSession(
        name: 'Quick',
        warmUp: [],
        items: [BuiltItem(exerciseNumber: 1, sets: 1, reps: 8)],
        coolDown: [],
        estimatedMinutes: 2,
      ),
    );
    await pump(t, const WorkoutScreen(request: request));
    expect(find.text('00:10'), findsOneWidget);
    await t.tap(find.text('+10s'));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('00:20'), findsOneWidget);
    await t.tap(find.text('+10s'));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('00:30'), findsOneWidget);
    // Finish the session so no timer is left running.
    await t.tap(find.text('Skip'));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.byTooltip('Next'));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.text('Easy'));
    await t.pump(const Duration(milliseconds: 400));
  });

  testWidgets('music button toggles the musicEnabled setting', (t) async {
    t.view.physicalSize = const Size(800, 1600);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    const request = WorkoutRequest(
      templateId: 'daily',
      session: BuiltSession(
        name: 'Quick',
        warmUp: [],
        items: [BuiltItem(exerciseNumber: 1, sets: 1, reps: 8)],
        coolDown: [],
        estimatedMinutes: 2,
      ),
    );
    final container = await pump(t, const WorkoutScreen(request: request));
    await t.tap(find.text('Skip'));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Music on'), findsOneWidget);
    await t.tap(find.byTooltip('Turn music off'));
    await t.pump(const Duration(milliseconds: 400));
    expect(container.read(settingsProvider)['musicEnabled'], false);
    expect(find.text('Music off'), findsOneWidget);
    await t.tap(find.byTooltip('Next'));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.text('Easy'));
    await t.pump(const Duration(milliseconds: 400));
  });

  testWidgets('coach shows honest unavailable state with input disabled', (
    t,
  ) async {
    await pump(t, const CoachScreen());
    expect(find.textContaining("isn't connected yet"), findsWidgets);
    expect(t.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });
}
