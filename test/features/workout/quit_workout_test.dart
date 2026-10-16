import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/plans/domain/plan_builder.dart';
import 'package:calisthenics/features/user/presentation/providers/user_providers.dart';
import 'package:calisthenics/features/workout/domain/workout_request.dart';
import 'package:calisthenics/features/workout/presentation/screens/workout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'foundation-full-body|2026-10-14';
const _request = WorkoutRequest(
  templateId: 'foundation-full-body',
  progressKey: _key,
  session: BuiltSession(
    name: 'Quick',
    warmUp: [92],
    items: [BuiltItem(exerciseNumber: 1, sets: 1, reps: 8)],
    coolDown: [],
    estimatedMinutes: 2,
  ),
);

Future<ProviderContainer> _open(WidgetTester t) async {
  t.view.physicalSize = const Size(800, 1600);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: '/w',
        builder: (_, s) => WorkoutScreen(request: s.extra! as WorkoutRequest),
      ),
    ],
  );
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  router.push('/w', extra: _request);
  await t.pump(const Duration(milliseconds: 500));
  // First up -> warm-up drill running -> "next" finishes it: 1 of 2 steps done.
  await t.tap(find.text('Skip'));
  await t.pump(const Duration(milliseconds: 400));
  await t.tap(find.byTooltip('Next'));
  await t.pump(const Duration(milliseconds: 400));
  return container;
}

Future<void> _openQuitDialog(WidgetTester t) async {
  await t.pump(const Duration(milliseconds: 600));
  await t.tap(find.byTooltip('Quit workout').first);
  await t.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('both buttons sit in one row and Keep going resumes', (t) async {
    await _open(t);
    await _openQuitDialog(t);
    expect(find.text('Quit workout?'), findsOneWidget);
    expect(find.text('Mark this day as complete'), findsOneWidget);
    final keep = t.getCenter(find.text('Keep going'));
    final quit = t.getCenter(find.text('Quit'));
    expect((keep.dy - quit.dy).abs(), lessThan(2)); // same row
    expect(keep.dx, lessThan(quit.dx));
    await t.tap(find.text('Keep going'));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Quit workout?'), findsNothing);
    expect(find.text('home'), findsNothing); // still in the player
    // Leave so no timer is left running.
    await _openQuitDialog(t);
    await t.tap(find.text('Quit'));
    await t.pump(const Duration(milliseconds: 600));
  });

  testWidgets('quit without the tick saves progress, not a finished day', (
    t,
  ) async {
    final c = await _open(t);
    await _openQuitDialog(t);
    expect(find.textContaining('50% through'), findsOneWidget);
    await t.tap(find.text('Quit'));
    await t.pump(const Duration(milliseconds: 600));
    expect(c.read(historyProvider), isEmpty);
    expect(c.read(partialProgressProvider)[_key], 50);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('quit with the tick marks the day complete', (t) async {
    final c = await _open(t);
    await _openQuitDialog(t);
    await t.tap(find.text('Mark this day as complete'));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('Quit'));
    await t.pump(const Duration(milliseconds: 600));
    expect(c.read(historyProvider), hasLength(1));
    expect(c.read(historyProvider).single.templateId, 'foundation-full-body');
    expect(c.read(partialProgressProvider), isEmpty);
    expect(find.text('home'), findsOneWidget);
  });
}
