import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:calisthenics/features/user/presentation/providers/user_providers.dart';
import 'package:calisthenics/features/workout/domain/workout_request.dart';
import 'package:calisthenics/features/workout/domain/workout_state.dart';
import 'package:calisthenics/features/workout/domain/workout_steps.dart';
import 'package:calisthenics/features/workout/presentation/screens/workout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('state', () {
    test('a try-out starts working, then is done: no preview, no rating', () {
      final req = WorkoutRequest.demo(1, 'Wall Push-Up');
      expect(req.demo, isTrue);
      final steps = buildSteps(req.session);
      expect(steps, hasLength(1));
      expect(steps.single.seconds, 30);
      final s = WorkoutState.start(steps, demo: true);
      expect(s.phase, WorkoutPhase.work);
      expect(s.phaseSeconds, 30);
      expect(s.finishStep().phase, WorkoutPhase.done);
    });

    test(
      'a normal session still opens with First up and asks for a rating',
      () {
        final steps = buildSteps(WorkoutRequest.demo(1, 'x').session);
        final s = WorkoutState.start(steps);
        expect(s.phase, WorkoutPhase.preview);
        expect(s.startWork().finishStep().phase, WorkoutPhase.rating);
      },
    );
  });

  group('screens', () {
    Future<(ProviderContainer, GoRouter)> open(
      WidgetTester t,
      String start,
    ) async {
      t.view.physicalSize = const Size(800, 1600);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      SharedPreferences.setMockInitialValues({
        'user_subscription':
            '{"plan":"yearly","renewsAt":"2099-01-01T00:00:00.000"}',
      });
      final sp = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
      );
      addTearDown(container.dispose);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('home')),
          ),
          GoRoute(
            path: '/exercise',
            builder: (_, _) => ExerciseDetailScreen(number: 1),
          ),
          GoRoute(
            path: '/workout',
            builder: (_, s) =>
                WorkoutScreen(request: s.extra! as WorkoutRequest),
          ),
        ],
      );
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      router.push(start);
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      return (container, router);
    }

    testWidgets(
      'the exercise page has a Play button that opens the 30 s player',
      (t) async {
        final (c, _) = await open(t, '/exercise');
        expect(find.byKey(const ValueKey('exercise-play')), findsOneWidget);
        await t.tap(find.byKey(const ValueKey('exercise-play')));
        await t.pump();
        await t.pump(const Duration(milliseconds: 600));
        // Same player UI, straight into the exercise: a 30 s countdown, no First up.
        expect(find.text('00:30'), findsOneWidget);
        expect(find.text('FIRST UP'), findsNothing);
        expect(find.byTooltip('Pause'), findsOneWidget);
        // The cross goes straight back, without a quit dialog.
        await t.tap(find.byTooltip('Quit workout').first);
        await t.pump();
        await t.pump(const Duration(milliseconds: 600));
        await t.pump(const Duration(milliseconds: 600));
        expect(find.text('Quit workout?'), findsNothing);
        expect(find.text('00:30'), findsNothing);
        expect(find.byKey(const ValueKey('exercise-play')), findsOneWidget);
        expect(c.read(historyProvider), isEmpty);
      },
    );

    testWidgets('when the 30 seconds end it returns, saving nothing', (
      t,
    ) async {
      final (c, _) = await open(t, '/exercise');
      await t.tap(find.byKey(const ValueKey('exercise-play')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      // Let the 30 seconds run out.
      for (var i = 0; i < 32; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      await t.pump(const Duration(milliseconds: 800));
      await t.pump(const Duration(milliseconds: 800));
      expect(find.text('WORKOUT COMPLETE'), findsNothing);
      expect(find.text('How did that feel?'), findsNothing);
      expect(find.byKey(const ValueKey('exercise-play')), findsOneWidget);
      expect(c.read(historyProvider), isEmpty);
      expect(c.read(partialLogProvider), isEmpty);
    });
  });
}
