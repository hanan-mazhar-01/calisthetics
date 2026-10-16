import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/glass_sheet.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../providers/reminder_providers.dart';

/// Turn the training reminder on or off and choose its time.
Future<void> showReminderSheet(BuildContext context) =>
    showGlassSheet<void>(context, builder: (_) => const _ReminderSheet());

class _ReminderSheet extends ConsumerStatefulWidget {
  const _ReminderSheet();

  @override
  ConsumerState<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends ConsumerState<_ReminderSheet> {
  bool _blocked = false;

  Future<void> _setEnabled(bool on) async {
    final settings = ref.read(settingsProvider.notifier);
    if (!on) {
      await settings.set('reminderEnabled', false);
      return;
    }
    final service = ref.read(reminderServiceProvider);
    final granted = await service.requestPermission();
    if (!mounted) return;
    setState(() => _blocked = !granted);
    if (!granted) return;
    final current = ref.read(settingsProvider);
    if (parseReminderTime(current['reminderTime'] as String?) == null) {
      await settings.set(
        'reminderTime',
        formatReminderTime(
          defaultReminderTime(current['timeOfDay'] as String?),
        ),
      );
    }
    await settings.set('reminderEnabled', true);
  }

  Future<void> _pickTime(TimeOfDay initial) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await ref
        .read(settingsProvider.notifier)
        .set('reminderTime', formatReminderTime(picked));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final setting = ref.watch(reminderSettingProvider);
    final enabled = setting?.enabled ?? false;
    final time =
        setting?.time ??
        defaultReminderTime(
          ref.watch(settingsProvider)['timeOfDay'] as String?,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Training reminder',
          style: AppTypography.title(20, c.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'A notification on the days your plan trains.',
          style: AppTypography.body(c.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: enabled,
          onChanged: _setEnabled,
          title: Text(
            'Remind me',
            style: AppTypography.title(16, c.textPrimary),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          enabled: enabled,
          onTap: enabled ? () => _pickTime(time) : null,
          title: Text('Time', style: AppTypography.title(16, c.textPrimary)),
          trailing: Text(
            time.format(context),
            style: AppTypography.title(16, c.accentText),
          ),
        ),
        if (_blocked)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Notifications are blocked for Calesthetics. Allow them in your '
              "phone's settings to get reminders.",
              style: AppTypography.body(c.textSecondary, fontSize: 13),
            ),
          ),
      ],
    );
  }
}
