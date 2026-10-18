import 'dart:convert';

import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/plan/domain/plan_showcase.dart';
import 'package:calisthenics/features/plan/presentation/screens/all_plans_screen.dart';
import 'package:calisthenics/features/plan/presentation/screens/plan_details_screen.dart';
import 'package:calisthenics/features/plans/data/plan_templates.dart';
import 'package:calisthenics/features/plans/domain/plan_template.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:calisthenics/features/user/domain/active_plan.dart';
import 'package:calisthenics/features/user/presentation/providers/user_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

PlanTemplate _t(String id) => planTemplates.firstWhere((t) => t.id == id);

const _premium = {
  'user_subscription': '{"plan":"yearly","renewsAt":"2099-01-01T00:00:00.000"}',
};

void main() {
  group('what the cards say', () {
    test('equipment, length and tags come from the plan itself', () {
      final foundation = _t('foundation-full-body');
      expect(planEquipmentLabel(foundation), 'Wall +2');
      expect(planLengthLabel(foundation), '1 Stage : 4 Weeks');
      expect(planTags(foundation), ['Start here', 'Beginner', 'Full body']);
      final skill = _t('skill-push-up');
      expect(
        planLengthLabel(skill),
        '${skill.stages.length} Stage : '
        '${skill.stages.length * 4} Weeks',
      );
      expect(planTags(skill)[2], 'Skill');
    });

    test('every plan has areas, four gains and a brief', () {
      for (final t in planTemplates) {
        expect(planAreas(t), isNotEmpty, reason: t.id);
        expect(planAreas(t).every(planAreaIds.contains), isTrue, reason: t.id);
        expect(planGains(t), hasLength(4), reason: t.id);
        expect(t.description, isNotEmpty, reason: t.id);
      }
      expect(planAreas(_t('legs-and-glutes')), {'glutes', 'legs'});
      expect(planAreas(_t('foundation-full-body')), planAreaIds.toSet());
    });
  });

  group('screens', () {
    Future<(ProviderContainer, List<String>)> pump(
      WidgetTester tester, {
      String start = '/plans',
      Map<String, Object> extra = const {},
      bool withPlan = true,
    }) async {
      tester.view.physicalSize = const Size(900, 2800);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final plan = ActivePlan(
        templateId: 'foundation-full-body',
        startDate: DateTime(2026, 10, 12),
        profile: const UserProfile(daysPerWeek: 3),
      );
      SharedPreferences.setMockInitialValues({
        if (withPlan) 'user_active_plan': jsonEncode(plan.toJson()),
        ...extra,
      });
      final sp = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sp),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 12, 9)),
        ],
      );
      addTearDown(container.dispose);
      final went = <String>[];
      final router = GoRouter(
        initialLocation: start,
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) {
              went.add('/home');
              return const Scaffold(body: Text('HOME'));
            },
          ),
          GoRoute(path: '/plans', builder: (_, _) => const AllPlansScreen()),
          GoRoute(
            path: '/plans/:id',
            builder: (_, s) =>
                PlanDetailsScreen(templateId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: '/paywall',
            builder: (_, _) {
              went.add('/paywall');
              return const Scaffold(body: Text('PAYWALL'));
            },
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      return (container, went);
    }

    testWidgets('lists My Plan first, then the other plans', (tester) async {
      await pump(tester);
      expect(find.text('All Plan'), findsOneWidget);
      expect(find.text('My Plan'), findsOneWidget);
      expect(find.text('Other Plan'), findsOneWidget);
      expect(find.text('Current plan'), findsOneWidget);
      expect(find.text('Full-Body Foundation'), findsOneWidget);
      expect(find.text('Core Control'), findsOneWidget);
    });

    testWidgets('a card opens the plan details', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Core Control'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Plan Details'), findsOneWidget);
      expect(find.text('Focus'), findsOneWidget);
      expect(find.text('Brief'), findsOneWidget);
      expect(find.text("You'll Gain"), findsOneWidget);
      expect(find.text('Join'), findsOneWidget);
    });

    testWidgets('Free: Join opens the paywall and adds nothing', (
      tester,
    ) async {
      final (c, went) = await pump(tester, start: '/plans/core-control');
      await tester.tap(find.text('Join'));
      await tester.pump(const Duration(seconds: 1));
      expect(went, ['/paywall']);
      expect(c.read(ownedPlansProvider), hasLength(1));
    });

    testWidgets('Premium: Join, then Not now keeps the current plan', (
      tester,
    ) async {
      final (c, went) = await pump(
        tester,
        start: '/plans/core-control',
        extra: _premium,
      );
      await tester.tap(find.text('Join'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Switch the plan now?'), findsOneWidget);
      expect(
        find.textContaining("You've joined 'Core Control'"),
        findsOneWidget,
      );
      await tester.tap(find.text('NOT NOW'));
      await tester.pump(const Duration(seconds: 1));
      expect(c.read(ownedPlansProvider), hasLength(2));
      expect(c.read(activePlanProvider)!.templateId, 'foundation-full-body');
      expect(went, ['/home']);
    });

    testWidgets('Premium: Join, then Switch now makes it current', (
      tester,
    ) async {
      final (c, went) = await pump(
        tester,
        start: '/plans/core-control',
        extra: _premium,
      );
      await tester.tap(find.text('Join'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('SWITCH NOW'));
      await tester.pump(const Duration(seconds: 1));
      expect(c.read(activePlanProvider)!.templateId, 'core-control');
      expect(went, ['/home']);
    });

    testWidgets('with no plan yet, joining makes it current, no question', (
      tester,
    ) async {
      final (c, went) = await pump(
        tester,
        start: '/plans/core-control',
        withPlan: false,
      );
      await tester.tap(find.text('Join'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Switch the plan now?'), findsNothing);
      expect(c.read(activePlanProvider)!.templateId, 'core-control');
      expect(went, ['/home']);
    });

    testWidgets('your own plan shows Current plan, greyed', (tester) async {
      await pump(tester, start: '/plans/foundation-full-body');
      expect(find.text('Current plan'), findsWidgets);
      expect(find.text('Join'), findsNothing);
    });
  });
}
