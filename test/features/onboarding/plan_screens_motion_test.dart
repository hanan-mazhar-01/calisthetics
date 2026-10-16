import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/core/theme/app_theme.dart';
import 'package:calisthenics/features/onboarding/domain/onboarding_step.dart';
import 'package:calisthenics/features/onboarding/presentation/widgets/plan_preview_step_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _phases = [
  for (var i = 1; i <= 4; i++)
    ProgramPhase(
      number: '0$i',
      label: 'Week $i',
      weekRange: 'Days',
      exercises: ['Squat', 'Bridge', 'Lunge', 'Step-Up'],
      sessionName: 'Session $i',
      exerciseNumbers: [18, 21, 19, 23],
      targets: ['30s', '30s', '30s', '30s'],
    ),
];

Future<void> _pump(WidgetTester t, {bool still = false}) async {
  SharedPreferences.setMockInitialValues({});
  final sp = await SharedPreferences.getInstance();
  t.view.physicalSize = const Size(400, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(400, 900),
            disableAnimations: still,
          ),
          child: Scaffold(
            body: PlanPreviewStepView(
              step: PlanPreviewStep(
                id: 'plan-preview',
                headline: const Headline('Four ', 'phases', '.'),
                phases: _phases,
                ctaLabel: 'Get my plan',
              ),
              onNext: () {},
            ),
          ),
        ),
      ),
    ),
  );
}

double _opacityOf(WidgetTester t, Finder inside) {
  final opacities = t.widgetList<Opacity>(
    find.ancestor(of: inside, matching: find.byType(Opacity)),
  );
  return opacities.fold<double>(1, (a, o) => a * o.opacity);
}

void main() {
  testWidgets('phases appear one after another, then the button', (t) async {
    await _pump(t);
    await t.pump(const Duration(milliseconds: 1300));
    // Early on, the first phase is in and the last is not yet.
    expect(_opacityOf(t, find.text('01')), greaterThan(0.9));
    expect(_opacityOf(t, find.text('04')), lessThan(0.1));
    expect(_opacityOf(t, find.text('Get my plan')), lessThan(0.1));
    await t.pump(const Duration(milliseconds: 1200));
    expect(_opacityOf(t, find.text('02')), greaterThan(0.9));
    expect(_opacityOf(t, find.text('04')), lessThan(0.1));
    await t.pump(const Duration(seconds: 5));
    for (final n in ['01', '02', '03', '04']) {
      expect(_opacityOf(t, find.text(n)), 1.0, reason: n);
    }
    expect(_opacityOf(t, find.text('Get my plan')), 1.0);
  });

  testWidgets('with animations off everything shows at once', (t) async {
    await _pump(t, still: true);
    await t.pump();
    expect(_opacityOf(t, find.text('04')), 1.0);
    expect(_opacityOf(t, find.text('Get my plan')), 1.0);
  });
}
