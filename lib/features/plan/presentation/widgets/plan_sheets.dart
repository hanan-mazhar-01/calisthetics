import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/glass_sheet.dart';
import '../../../plans/data/plan_templates.dart';
import '../../../plans/domain/plan_template.dart';
import '../../../plans/domain/user_profile.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../providers/plan_providers.dart';

/// Lets the user pick a plan; starting it replaces the current one.
Future<void> showPlanPicker(
  BuildContext context, {
  String title = 'Choose a plan',
}) {
  return showGlassSheet<void>(
    context,
    builder: (_) => _PlanPickerSheet(title: title),
  );
}

class _PlanPickerSheet extends ConsumerWidget {
  const _PlanPickerSheet({required this.title});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final active = ref.watch(activePlanProvider);
    final ownedIds = {
      for (final p in ref.watch(ownedPlansProvider)) p.templateId,
    };
    final profile = active?.profile ?? const UserProfile();
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.title(20, c.textPrimary)),
          const SizedBox(height: 4),
          Text(
            'Adding a plan starts it today and makes it your current plan. Your other plans stay.',
            style: AppTypography.body(c.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: planTemplates.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final t = planTemplates[i];
                return GlassCard(
                  padding: const EdgeInsets.all(14),
                  selected: t.id == active?.templateId,
                  onTap: () {
                    final notifier = ref.read(activePlanProvider.notifier);
                    if (ownedIds.contains(t.id)) {
                      // Already added: just switch to it.
                      notifier.switchTo(t.id);
                    } else if (!ref.read(canAddPlanProvider)) {
                      // Free keeps one plan; more need Premium.
                      final router = GoRouter.of(context);
                      Navigator.of(context).pop();
                      router.push('/paywall');
                      return;
                    } else {
                      notifier.start(t, profile);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.name,
                              style: AppTypography.title(15, c.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${t.tagline} · ${_stagesLabel(t)}',
                              style: AppTypography.body(
                                c.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (t.id == active?.templateId)
                        Icon(Icons.check_circle_rounded, color: c.accentText)
                      else if (ownedIds.contains(t.id))
                        Text(
                          'Added',
                          style: AppTypography.body(
                            c.textMuted,
                            fontSize: 12.5,
                            weight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _stagesLabel(PlanTemplate t) =>
      t.stages.length == 1 ? '1 stage' : '${t.stages.length} stages';
}
