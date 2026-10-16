import 'dart:convert';

import 'package:calisthenics/core/storage/shared_preferences_provider.dart';
import 'package:calisthenics/features/plans/data/plan_templates.dart';
import 'package:calisthenics/features/plans/domain/user_profile.dart';
import 'package:calisthenics/features/user/domain/active_plan.dart';
import 'package:calisthenics/features/user/presentation/providers/user_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _core = planTemplates.firstWhere((t) => t.id == 'core-control');
final _legs = planTemplates.firstWhere((t) => t.id == 'legs-and-glutes');

Future<ProviderContainer> _container([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test(
    'starting a second plan keeps the first and makes the new one current',
    () async {
      final c = await _container();
      final plans = c.read(activePlanProvider.notifier);
      await plans.start(_core, const UserProfile());
      await plans.start(_legs, const UserProfile());
      expect(c.read(ownedPlansProvider).map((p) => p.templateId), [
        'core-control',
        'legs-and-glutes',
      ]);
      expect(c.read(activePlanProvider)!.templateId, 'legs-and-glutes');
    },
  );

  test('switching changes the current plan only', () async {
    final c = await _container();
    final plans = c.read(activePlanProvider.notifier);
    await plans.start(_core, const UserProfile());
    await plans.start(_legs, const UserProfile());
    await plans.switchTo('core-control');
    expect(c.read(activePlanProvider)!.templateId, 'core-control');
    expect(c.read(ownedPlansProvider).length, 2);
  });

  test(
    'removing the current plan falls back to another; clear removes all',
    () async {
      final c = await _container();
      final plans = c.read(activePlanProvider.notifier);
      await plans.start(_core, const UserProfile());
      await plans.start(_legs, const UserProfile());
      await plans.remove('legs-and-glutes');
      expect(c.read(activePlanProvider)!.templateId, 'core-control');
      await plans.clear();
      expect(c.read(activePlanProvider), isNull);
      expect(c.read(ownedPlansProvider), isEmpty);
    },
  );

  test('editing preferences updates only the current plan', () async {
    final c = await _container();
    final plans = c.read(activePlanProvider.notifier);
    await plans.start(_core, const UserProfile(sessionMinutes: 15));
    await plans.start(_legs, const UserProfile(sessionMinutes: 15));
    await plans.updateProfile(const UserProfile(sessionMinutes: 30));
    final owned = {
      for (final p in c.read(ownedPlansProvider))
        p.templateId: p.profile.sessionMinutes,
    };
    expect(owned, {'core-control': 15, 'legs-and-glutes': 30});
  });

  test('a plan saved by an older version is picked up and kept', () async {
    final legacy = ActivePlan(
      templateId: 'core-control',
      startDate: DateTime(2026, 10, 12),
      profile: const UserProfile(),
    );
    final c = await _container({
      'user_active_plan': jsonEncode(legacy.toJson()),
    });
    expect(c.read(activePlanProvider)!.templateId, 'core-control');
    expect(c.read(ownedPlansProvider).length, 1);
  });

  test('plans survive an app restart', () async {
    final c = await _container();
    final plans = c.read(activePlanProvider.notifier);
    await plans.start(_core, const UserProfile());
    await plans.start(_legs, const UserProfile());
    await plans.switchTo('core-control');
    final prefs = c.read(sharedPreferencesProvider);
    final again = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(again.dispose);
    expect(again.read(ownedPlansProvider).length, 2);
    expect(again.read(activePlanProvider)!.templateId, 'core-control');
  });
}
