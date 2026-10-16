import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/features/plan/domain/plan_timeline.dart';
import 'package:calisthenics/features/plans/data/plan_templates.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:calisthenics/features/user/domain/completed_session.dart';
import 'package:calisthenics/features/user/presentation/providers/user_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('restarting from Day 1 forgets earlier progress on that plan', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var now = DateTime(2026, 10, 13, 9, 0);
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    final template = planTemplates.firstWhere(
      (t) => t.id == 'foundation-full-body',
    );
    final plans = c.read(activePlanProvider.notifier);
    await plans.start(template, const UserProfile());

    int doneDays() {
      final plan = c.read(activePlanProvider)!;
      return PlanTimeline.build(
        template: template,
        plan: plan,
        history: c.read(historyProvider),
        today: now,
      ).doneDays;
    }

    now = DateTime(2026, 10, 13, 10, 0);
    await c
        .read(historyProvider.notifier)
        .add(
          CompletedSession(
            finishedAt: now,
            templateId: template.id,
            sessionName: 'Upper',
            durationSeconds: 600,
            exerciseNumbers: const [1],
          ),
        );
    await c
        .read(partialProgressProvider.notifier)
        .set('foundation-full-body|2026-10-14', 40);
    expect(doneDays(), 1);

    // Restart later the same day: nothing done yet, partial progress cleared.
    now = DateTime(2026, 10, 13, 11, 0);
    await plans.restart();
    expect(doneDays(), 0);
    expect(c.read(partialProgressProvider), isEmpty);
    expect(c.read(activePlanProvider)!.stageIndex, 0);

    // A workout after the restart counts again; the old one still does not.
    now = DateTime(2026, 10, 13, 12, 0);
    await c
        .read(historyProvider.notifier)
        .add(
          CompletedSession(
            finishedAt: now,
            templateId: template.id,
            sessionName: 'Upper',
            durationSeconds: 600,
            exerciseNumbers: const [1],
          ),
        );
    expect(doneDays(), 1);
    // History itself is kept.
    expect(c.read(historyProvider), hasLength(2));
  });
}
