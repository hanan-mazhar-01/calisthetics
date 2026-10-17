import 'package:calisthenics/features/discover/domain/discover_logic.dart';
import 'package:calisthenics/features/discover/domain/exercise_access_policy.dart';
import 'package:calisthenics/features/discover/presentation/screens/discover_screen.dart';
import 'package:calisthenics/features/exercises/data/exercise_catalog.dart';
import 'package:calisthenics/features/exercises/domain/exercise.dart';
import 'package:calisthenics/features/exercises/domain/exercise_lookup.dart';
import 'package:calisthenics/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:calisthenics/features/plans/data/plan_templates.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:calisthenics/features/user/domain/active_plan.dart';
import 'package:calisthenics/features/user/domain/completed_session.dart';
import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('search & filter', () {
    test('empty query returns all 115', () {
      expect(searchExercises('').length, 115);
    });

    test('matches by name, case-insensitive, all words', () {
      final r = searchExercises('PUSH up');
      expect(r, isNotEmpty);
      expect(
        r.every(
          (e) =>
              e.name.toLowerCase().contains('push') &&
              e.name.toLowerCase().contains('up'),
        ),
        isTrue,
      );
      expect(searchExercises('zzzz'), isEmpty);
    });

    test('level and equipment filters', () {
      final beg = searchExercises(
        '',
        filters: const DiscoverFilters(levels: {ExerciseLevel.beginner}),
      );
      expect(beg.every((e) => e.level == ExerciseLevel.beginner), isTrue);
      final wall = searchExercises(
        '',
        filters: const DiscoverFilters(equipment: {EquipmentTag.wall}),
      );
      expect(wall, isNotEmpty);
      expect(
        wall.every((e) => equipmentTagsOf(e).contains(EquipmentTag.wall)),
        isTrue,
      );
    });

    test('favorites filter', () {
      final r = searchExercises(
        '',
        filters: const DiscoverFilters(favoritesOnly: true),
        favorites: {1, 5},
      );
      expect(r.map((e) => e.number), [1, 5]);
    });

    test('every exercise gets at least one equipment tag', () {
      for (final e in exerciseCatalog) {
        expect(equipmentTagsOf(e), isNotEmpty, reason: e.equipment);
      }
    });
  });

  group('current rung', () {
    final template = planTemplates.firstWhere((t) => t.id == 'skill-push-up');
    ActivePlan planAt(int stage) => ActivePlan(
      templateId: template.id,
      startDate: DateTime(2026, 1, 1),
      profile: const UserProfile(),
      stageIndex: stage,
    );

    test('no plan, no history: first rung', () {
      expect(
        currentRungFor('pull-up').number,
        ladderFor('pull-up').first.number,
      );
    });

    test('active skill plan: hardest rung in the current stage', () {
      final ladder = ladderFor('push-up');
      final foundation = currentRungFor(
        'push-up',
        plan: planAt(0),
        template: template,
      );
      final build = currentRungFor(
        'push-up',
        plan: planAt(1),
        template: template,
      );
      expect(ladder.indexOf(build), greaterThan(ladder.indexOf(foundation)));
    });

    test('other skill falls back to history', () {
      final ladder = ladderFor('pull-up');
      final session = CompletedSession(
        finishedAt: DateTime(2026, 1, 2),
        templateId: 'x',
        sessionName: 's',
        durationSeconds: 60,
        exerciseNumbers: [ladder[2].number],
      );
      expect(
        currentRungFor(
          'pull-up',
          plan: planAt(2),
          template: template,
          history: [session],
        ).number,
        ladder[2].number,
      );
    });

    test('neighbours', () {
      final ladder = ladderFor('dips');
      final n = neighboursOf(ladder[1]);
      expect(n.easier, ladder[0]);
      expect(n.harder, ladder[2]);
      expect(neighboursOf(ladder.first).easier, isNull);
      expect(neighboursOf(ladder.last).harder, isNull);
    });
  });

  group('access policy', () {
    final rung = ladderFor('handstand')[3];
    final foundation = exercisesInSection('foundation-core').first;

    test('pages are visible to everyone', () {
      const p = ExerciseAccessPolicy(isPremium: false);
      expect(p.canViewPage(rung), isTrue);
    });

    test('free: ladder video locked unless in own plan; foundation free', () {
      const free = ExerciseAccessPolicy(isPremium: false);
      expect(free.canPlayVideo(rung), isFalse);
      expect(free.canPlayVideo(foundation), isTrue);
      expect(
        ExerciseAccessPolicy(
          isPremium: false,
          planExerciseNumbers: {rung.number},
        ).canPlayVideo(rung),
        isTrue,
      );
    });

    test('premium plays everything and can start plans', () {
      const p = ExerciseAccessPolicy(isPremium: true);
      expect(p.canPlayVideo(rung), isTrue);
      expect(p.canStartPlan, isTrue);
      expect(
        const ExerciseAccessPolicy(isPremium: false).canStartPlan,
        isFalse,
      );
    });
  });

  group('widgets', () {
    Future<Widget> app(Widget home) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      return ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(theme: AppTheme.light, home: home),
      );
    }

    testWidgets('Discover shows its sections and category chips', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(await app(const DiscoverScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Skill ladders'), findsOneWidget);
      expect(find.text('Target Area'), findsOneWidget);
      expect(find.text('Continue your ladder'), findsNothing);
      // The chip row scrolls sideways, so only the first chips are built.
      for (final chip in ['All', 'Favorites', 'Skills', 'Upper body', 'Core']) {
        expect(find.text(chip), findsWidgets, reason: chip);
      }
    });

    testWidgets(
      'search pill opens full-screen search with chips, then results',
      (tester) async {
        await tester.pumpWidget(await app(const DiscoverScreen()));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Search exercises'));
        await tester.pumpAndSettle();
        // Chip groups show while nothing is typed.
        for (final title in ['Skills', 'Difficulty', 'Equipment']) {
          expect(find.text(title), findsOneWidget, reason: title);
        }
        await tester.enterText(find.byType(TextField), 'pistol');
        await tester.pumpAndSettle();
        expect(find.text('Difficulty'), findsNothing);
        expect(find.textContaining('Pistol'), findsWidgets);
        // X closes and the tab is back to browsing.
        await tester.tap(find.bySemanticsLabel('Close search'));
        await tester.pumpAndSettle();
        expect(find.text('Skill ladders'), findsOneWidget);
      },
    );

    testWidgets('Detail shows placeholder and catalog content', (tester) async {
      tester.view.physicalSize = const Size(1000, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final e = exerciseByNumber(1);
      await tester.pumpWidget(await app(ExerciseDetailScreen(number: 1)));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(e.name), findsWidgets);
      // Nothing plays by itself: the thumbnail with a play button.
      expect(find.textContaining('Tap to try it'), findsOneWidget);
      expect(find.text('How to'), findsOneWidget);
    });
  });
}
