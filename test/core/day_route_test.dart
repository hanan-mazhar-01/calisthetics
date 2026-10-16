import 'package:calisthenics/core/routing/app_router.dart';
import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/onboarding/presentation/providers/onboarding_completed_provider.dart';
import 'package:calisthenics/features/plan/presentation/screens/day_overview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('the /day route passes the week to the Day screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({onboardingCompletedKey: true});
    final sp = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    router.go('/day/2?week=3');
    await tester.pump(const Duration(seconds: 1));
    final screen = tester.widget<DayOverviewScreen>(
      find.byType(DayOverviewScreen),
    );
    expect(screen.weekday, 2);
    expect(screen.week, 3);

    router.go('/day/2');
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.widget<DayOverviewScreen>(find.byType(DayOverviewScreen)).week,
      isNull,
    );
  });
}
