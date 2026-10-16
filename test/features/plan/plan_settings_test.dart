import 'dart:convert';

import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/plan/presentation/providers/plan_settings_draft.dart';
import 'package:calisthenics/features/plan/presentation/screens/plan_settings_screen.dart';
import 'package:calisthenics/features/plans/data/plan_templates.dart';
import 'package:calisthenics/features/plans/domain/plan_template.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:calisthenics/features/user/domain/active_plan.dart';
import 'package:calisthenics/features/user/presentation/providers/user_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _template = planTemplates.firstWhere((t) => t.id == 'skill-push-up');
final _plan = ActivePlan(
  templateId: _template.id,
  startDate: DateTime(2026, 10, 12),
  profile: const UserProfile(sessionMinutes: 15),
);

Future<ProviderContainer> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 3200);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    'user_active_plan': jsonEncode(_plan.toJson()),
  });
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 14, 9)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const PlanSettingsScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return container;
}

void main() {
  testWidgets('shows the plan options and the sounds section', (tester) async {
    await _pump(tester);
    for (final t in [
      'Current Plan Settings',
      'Focus',
      'Workout Level',
      'Duration',
      'Avoid Areas',
      'UPDATE MY CURRENT PLAN',
      'Restart From Day1',
      'Sounds',
      'Music',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('Voice Guidance'), findsNothing);
    expect(find.text('15 mins'), findsOneWidget);
    expect(find.text('Beginner'), findsOneWidget);
  });

  testWidgets(
    'editing duration and level then updating changes the active plan',
    (tester) async {
      final container = await _pump(tester);

      // Each row opens the onboarding-style screen for that question.
      await tester.tap(find.text('Duration'));
      await tester.pumpAndSettle();
      expect(find.text('How long per '), findsNothing); // headline is rich text
      await tester.tap(find.text('20 min'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Workout Level'));
      // The level screen has a looping glow animation, so it never "settles".
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      // The slider labels its ends with the first and last level.
      await tester.tap(find.text('Advanced'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Nothing applied until the button is pressed.
      expect(container.read(activePlanProvider)!.profile.sessionMinutes, 15);

      await container
          .read(activePlanProvider.notifier)
          .updateProfile(container.read(planDraftProvider));
      final p = container.read(activePlanProvider)!;
      expect(p.profile.sessionMinutes, 20);
      expect(p.profile.level, PlanLevel.advanced);
      expect(p.stageIndex, 2); // advanced starts on the last stage
    },
  );

  testWidgets('avoiding wrists on a wrist-heavy plan shows a heads-up', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Avoid Areas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wrists'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('This plan loads your wrists'), findsOneWidget);
  });

  testWidgets('"None" is exclusive on the avoid-areas screen', (tester) async {
    final container = await _pump(tester);
    await tester.tap(find.text('Avoid Areas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wrists'));
    await tester.tap(find.text('Knees'));
    await tester.pumpAndSettle();
    expect(container.read(planDraftProvider).protectedAreas, {
      ProtectedArea.wrists,
      ProtectedArea.knees,
    });
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    expect(container.read(planDraftProvider).protectedAreas, isEmpty);
    await tester.tap(find.text('Shoulders'));
    await tester.pumpAndSettle();
    expect(container.read(planDraftProvider).protectedAreas, {
      ProtectedArea.shoulders,
    });
  });

  testWidgets('the focus row opens the body map and edits focus areas', (
    tester,
  ) async {
    final container = await _pump(tester);
    await tester.tap(find.text('Focus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Core'));
    await tester.pumpAndSettle();
    expect(container.read(planDraftProvider).focusAreas, contains('core'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Core'), findsOneWidget); // the row's value
  });

  testWidgets(
    '"Some experience" stays selected (it is not snapped back to Beginner)',
    (tester) async {
      final container = await _pump(tester);
      await tester.tap(find.text('Workout Level'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      // Slide to the second level: the slider's stops are 4 options, the plan has 3 levels.
      final slider = find.bySemanticsLabel('Level');
      expect(slider, findsOneWidget);
      await tester.tapAt(
        tester.getTopLeft(slider) +
            Offset(tester.getSize(slider).width / 3, 26),
      );
      await tester.pump(); // an animation only starts on its first frame
      await tester.pump(const Duration(milliseconds: 700));
      expect(container.read(planDraftExperienceProvider), 'some-experience');
      expect(container.read(planDraftProvider).level, PlanLevel.beginner);
      expect(find.text('Some experience'), findsWidgets);
    },
  );

  test('option id mappings round-trip', () {
    for (final l in PlanLevel.values) {
      expect(levelFromOptionId(levelOptionId(l)), l);
    }
    for (final m in [10, 15, 20]) {
      expect(durationFromOptionId(durationOptionId(m)), m);
    }
    expect(areaOptionIds(<ProtectedArea>{}), {'none'});
    expect(areasFromOptionIds({'knees', 'neck'}), {
      ProtectedArea.knees,
      ProtectedArea.neck,
    });
    expect(levelFromOptionId('some-experience'), PlanLevel.beginner);
  });
}
