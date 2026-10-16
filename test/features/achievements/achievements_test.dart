import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/achievements/presentation/screens/achievements_screen.dart';
import 'package:calisthenics/features/profile/domain/achievement_evaluator.dart';
import 'package:calisthenics/features/user/domain/completed_session.dart';
import 'package:calisthenics/features/user/domain/plank_attempt.dart';
import 'package:calisthenics/features/user/domain/user_stats.dart';
import 'package:calisthenics/features/user/presentation/providers/user_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CompletedSession _s(DateTime at, {List<int> exercises = const [1, 2]}) =>
    CompletedSession(
      finishedAt: at,
      templateId: 't',
      sessionName: 's',
      durationSeconds: 900,
      exerciseNumbers: exercises,
    );

class _History extends HistoryNotifier {
  _History(this.items);
  final List<CompletedSession> items;
  @override
  List<CompletedSession> build() => items;
}

void main() {
  final today = DateTime(2026, 10, 14);
  List<Achievement> evaluate(
    List<CompletedSession> h, {
    List<PlankAttempt> plank = const [],
    int plankBest = 0,
  }) => const AchievementEvaluator().evaluate(
    history: h,
    stats: UserStats.from(h, today: today),
    records: {'plankSeconds': plankBest},
    plank: plank,
  );
  Achievement byId(List<Achievement> l, String id) =>
      l.firstWhere((a) => a.id == id);

  group('evaluator', () {
    test('each medal knows the day it was earned', () {
      final h = [
        _s(DateTime(2026, 10, 1, 8)),
        _s(DateTime(2026, 10, 2, 8)),
        _s(DateTime(2026, 10, 3, 8)),
        _s(DateTime(2026, 10, 9, 8)),
        _s(DateTime(2026, 10, 10, 8)),
      ];
      final l = evaluate(h);
      expect(byId(l, 'day-1').unlockedAt, DateTime(2026, 10, 1, 8));
      expect(byId(l, 'day-2').unlockedAt, DateTime(2026, 10, 2, 8));
      expect(byId(l, 'streak-3').unlockedAt, DateTime(2026, 10, 3, 8));
      expect(byId(l, 'workouts-5').unlockedAt, DateTime(2026, 10, 10, 8));
      expect(byId(l, 'streak-7').unlocked, isFalse);
      expect(byId(l, 'streak-7').unlockedAt, isNull);
    });

    test('minutes, plank and explorer medals use real data', () {
      final h = [
        for (var i = 0; i < 3; i++)
          _s(
            DateTime(2026, 10, 1 + i),
            exercises: [for (var n = 0; n < 8; n++) i * 8 + n + 1],
          ),
      ];
      final l = evaluate(
        h,
        plank: [
          PlankAttempt(at: DateTime(2026, 10, 2), seconds: 35),
          PlankAttempt(at: DateTime(2026, 10, 9), seconds: 65),
        ],
        plankBest: 65,
      );
      expect(byId(l, 'minutes-30').unlockedAt, DateTime(2026, 10, 2));
      expect(byId(l, 'minutes-100').unlocked, isFalse);
      expect(byId(l, 'plank-30').unlockedAt, DateTime(2026, 10, 2));
      expect(byId(l, 'plank-60').unlockedAt, DateTime(2026, 10, 9));
      expect(byId(l, 'explorer').unlockedAt, DateTime(2026, 10, 3));
      expect(byId(l, 'explorer-50').unlocked, isFalse);
    });

    test('nothing is unlocked without history', () {
      expect(evaluate([]).where((a) => a.unlocked), isEmpty);
    });

    test('every medal has a tab, a number and a caption', () {
      for (final a in evaluate([])) {
        expect(a.number, isNotEmpty);
        expect(a.unit, isNotEmpty);
      }
    });
  });

  group('page', () {
    Future<void> open(WidgetTester t, List<CompletedSession> h) async {
      t.view.physicalSize = const Size(390, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sp),
            clockProvider.overrideWithValue(() => today),
            historyProvider.overrideWith(() => _History(h)),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const AchievementsScreen(),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 600));
    }

    testWidgets('shows tabs, the medal count and the grid', (t) async {
      await open(t, [_s(DateTime(2026, 10, 13, 8))]);
      expect(find.text('STREAK'), findsOneWidget);
      expect(find.text('Received '), findsNothing);
      expect(find.textContaining('Received'), findsOneWidget);
      expect(find.text('Second Day'), findsOneWidget);
      // Switch tabs.
      await t.tap(find.text('WORKOUT'));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('Five down'), findsOneWidget);
      await t.tap(find.text('TIME'));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('100 minutes'), findsOneWidget);
    });

    testWidgets('tapping the selected earned medal opens the celebration', (
      t,
    ) async {
      await open(t, [_s(DateTime(2026, 10, 13, 8))]);
      // The newest earned medal is featured; tap its name's medal in the grid.
      await t.tap(find.text('First Day').last);
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.text('First Day').last);
      await t.pump(const Duration(seconds: 1));
      expect(find.text('ACHIEVEMENT'), findsOneWidget);
      expect(find.text('SHARE'), findsOneWidget);
      await t.tap(find.byIcon(Icons.close_rounded));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('ACHIEVEMENT'), findsNothing);
    });
  });
}
