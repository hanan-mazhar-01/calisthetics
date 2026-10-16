import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../plan/presentation/widgets/plan_confirm_dialog.dart';
import '../../../user/domain/completed_session.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../domain/activity_log.dart';
import '../widgets/activity_tile.dart';
import '../widgets/add_activity_sheet.dart';

/// Everything she did on one day: totals, the activities, and Add Activity.
class DayActivityScreen extends ConsumerWidget {
  const DayActivityScreen({super.key, required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final list = activitiesOn(ref.watch(historyProvider), day);
    final minutes = (list.fold<int>(0, (a, s) => a + s.durationSeconds) / 60)
        .round();
    final exercises = list.fold<int>(0, (a, s) => a + s.exerciseNumbers.length);
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          SizedBox(height: pad.top + 6),
          Row(
            children: [
              Semantics(
                button: true,
                label: 'Back',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: SizedBox(
                    width: 52,
                    height: 48,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  dayTitle(day),
                  textAlign: TextAlign.center,
                  style: AppTypography.title(
                    19,
                    c.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 52),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _Total('Workouts', list.length),
                      _Total('Minutes', minutes),
                      _Total('Exercises', exercises),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Text(
                      'Nothing logged on this day.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body(c.textMuted, fontSize: 15),
                    ),
                  )
                else
                  for (final s in list.reversed) ...[
                    ActivityTile(
                      session: s,
                      onLongPress: s.isManual
                          ? () => _confirmDelete(context, ref, s)
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, pad.bottom + 16),
            child: Semantics(
              button: true,
              label: 'Add Activity',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => showAddActivity(context, day: day),
                child: Container(
                  height: 54,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Add Activity',
                    style: AppTypography.title(
                      17,
                      c.onAccent,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CompletedSession s,
  ) async {
    final ok = await showPlanConfirmDialog(
      context,
      title: 'Delete this activity?',
      message: '"${s.sessionName}" will be removed from your history.',
      confirmLabel: 'Delete',
    );
    if (ok) await ref.read(historyProvider.notifier).remove(s);
  }
}

class _Total extends StatelessWidget {
  const _Total(this.label, this.value);
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Expanded(
      child: Semantics(
        label: '$label: $value',
        excludeSemantics: true,
        child: Column(
          children: [
            Text(
              '$value',
              style: AppTypography.title(
                24,
                c.textPrimary,
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.body(c.textMuted, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}
