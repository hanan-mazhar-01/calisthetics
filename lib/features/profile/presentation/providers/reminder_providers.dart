import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/reminder_service.dart';
import '../../../plans/domain/plan_builder.dart';
import '../../../user/presentation/providers/user_providers.dart';

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => LocalReminderService(),
);

/// The reminder the user chose, or null when it is off.
typedef ReminderSetting = ({TimeOfDay time, bool enabled});

TimeOfDay? parseReminderTime(String? hhmm) {
  final p = hhmm?.split(':');
  if (p == null || p.length != 2) return null;
  final h = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
    return null;
  }
  return TimeOfDay(hour: h, minute: m);
}

String formatReminderTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// A sensible first reminder time from the onboarding "when do you train"
/// answer (morning / afternoon / evening).
TimeOfDay defaultReminderTime(String? timeOfDay) => switch (timeOfDay) {
  'afternoon' => const TimeOfDay(hour: 13, minute: 0),
  'evening' => const TimeOfDay(hour: 19, minute: 0),
  _ => const TimeOfDay(hour: 8, minute: 0),
};

final reminderSettingProvider = Provider<ReminderSetting?>((ref) {
  final settings = ref.watch(settingsProvider);
  final time = parseReminderTime(settings['reminderTime'] as String?);
  if (time == null) return null;
  return (time: time, enabled: settings['reminderEnabled'] == true);
});

/// Keeps the OS schedule in step with the reminder setting and the plan:
/// reminders fire on the weekdays the plan trains, at the chosen time.
/// Watch it once near the app root.
final reminderSyncProvider = Provider<void>((ref) {
  final setting = ref.watch(reminderSettingProvider);
  final plan = ref.watch(activePlanProvider);
  final service = ref.read(reminderServiceProvider);

  if (setting == null || !setting.enabled || plan == null) {
    service.cancelAll();
    return;
  }
  final weekdays = {
    for (final d in PlanBuilder.trainingWeekdays(plan.profile.daysPerWeek))
      d + 1,
  };
  service.schedule(time: setting.time, weekdays: weekdays);
});
