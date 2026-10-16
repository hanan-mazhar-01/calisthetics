import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../plans/domain/plan_template.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../providers/plan_providers.dart';
import 'plan_sheets.dart';

/// Colours per plan, in the app's warm family plus two cool accents.
List<Color> planGradient(PlanTemplate t) {
  const bySkill = {
    'push-up': [Color(0xFFD85F70), Color(0xFFE88A97)],
    'pull-up': [Color(0xFF8C4F7A), Color(0xFFB070A0)],
    'chin-up': [Color(0xFFE27A4E), Color(0xFFF0A07A)],
    'dips': [Color(0xFFB83B5E), Color(0xFFD8688A)],
    'handstand': [Color(0xFF5F7FA8), Color(0xFF8DA7C8)],
    'l-sit': [Color(0xFF6E8F7E), Color(0xFF9BB5A6)],
    'pistol-squat': [Color(0xFF9A6B8F), Color(0xFFC197B8)],
    'toes-to-bar': [Color(0xFFD99A65), Color(0xFFF0C48A)],
  };
  if (t.skillId != null) return bySkill[t.skillId]!;
  return switch (t.focus) {
    PlanFocus.fullBody => const [Color(0xFFD85F70), Color(0xFFE88A97)],
    PlanFocus.core => const [Color(0xFF8C4F7A), Color(0xFFB070A0)],
    PlanFocus.legsGlutes => const [Color(0xFF5F7FA8), Color(0xFF8DA7C8)],
    PlanFocus.conditioning => const [Color(0xFFE27A4E), Color(0xFFF0A07A)],
    PlanFocus.mobility => const [Color(0xFF6E8F7E), Color(0xFF9BB5A6)],
    PlanFocus.skill => const [Color(0xFFD85F70), Color(0xFFE88A97)],
  };
}

IconData _planIcon(PlanTemplate t) => switch (t.focus) {
  PlanFocus.fullBody => Icons.accessibility_new_rounded,
  PlanFocus.core => Icons.self_improvement_rounded,
  PlanFocus.legsGlutes => Icons.directions_run_rounded,
  PlanFocus.conditioning => Icons.bolt_rounded,
  PlanFocus.mobility => Icons.spa_rounded,
  PlanFocus.skill => Icons.stairs_rounded,
};

/// The expanded "Current Plan" panel: every plan the user added as a colourful
/// card (current one tagged, with its progress), then "Add More Plan".
/// Picking a card makes it the current plan, which re-themes the whole Plan tab.
class PlanDropdownPanel extends ConsumerWidget {
  const PlanDropdownPanel({
    super.key,
    required this.onClose,
    required this.maxHeight,
  });

  final VoidCallback onClose;
  final double maxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    // The current plan always comes first, then the others in the order added.
    final all = ref.watch(planCardsProvider);
    final cards = [
      ...all.where((c) => c.isCurrent),
      ...all.where((c) => !c.isCurrent),
    ];

    Future<void> addMore() async {
      if (ref.read(canAddPlanProvider)) {
        onClose();
        await showPlanPicker(context, title: 'Add a plan');
      } else {
        onClose();
        context.push('/paywall'); // Free: 1 plan. Premium: all.
      }
    }

    return Material(
      color: c.background,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.sm,
            AppSpacing.xxl,
            AppSpacing.xl,
          ),
          child: Column(
            children: [
              for (final card in cards) ...[
                _PlanCard(
                  data: card,
                  onTap: () async {
                    if (!card.isCurrent) {
                      await ref
                          .read(activePlanProvider.notifier)
                          .switchTo(card.plan.templateId);
                    }
                    onClose();
                  },
                  onRemove: () => _confirmRemove(context, ref, card),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Semantics(
                button: true,
                label: 'Add More Plan',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: addMore,
                  child: Container(
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: c.accent, width: 1.8),
                      color: c.surface,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: c.accentText, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Add More Plan',
                          style: AppTypography.title(
                            18,
                            c.accentText,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    PlanCardData card,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${card.template.name}?'),
        content: const Text(
          'The plan is removed from your list. Your workout history is kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(activePlanProvider.notifier).remove(card.plan.templateId);
    }
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.data,
    required this.onTap,
    required this.onRemove,
  });

  final PlanCardData data;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final colors = planGradient(data.template);
    return Semantics(
      button: true,
      selected: data.isCurrent,
      label:
          '${data.template.name}, ${data.doneDays} of ${data.totalDays} days${data.isCurrent ? ', current plan' : ''}',
      onLongPressHint: 'Remove plan',
      onLongPress: onRemove,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onRemove,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: data.isCurrent ? 176 : 156,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            border: Border.all(
              color: data.isCurrent ? c.accent : Colors.transparent,
              width: 3,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -14,
                bottom: -10,
                child: Icon(
                  _planIcon(data.template),
                  size: 128,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  data.isCurrent ? 44 : 18,
                  20,
                  18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 190),
                      child: Text(
                        data.template.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title(
                          26,
                          Colors.white,
                          weight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${data.doneDays} / ${data.totalDays} Days',
                      style: AppTypography.body(
                        Colors.white,
                        fontSize: 16,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PhaseDots(done: data.phaseDone),
                  ],
                ),
              ),
              if (data.isCurrent)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 7, 16, 9),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(18),
                      ),
                    ),
                    child: Text(
                      'Current plan',
                      style: AppTypography.title(
                        14,
                        c.accentText,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Four connected dots, one per phase; filled once that phase is finished.
class _PhaseDots extends StatelessWidget {
  const _PhaseDots({required this.done});
  final List<bool> done;

  @override
  Widget build(BuildContext context) {
    final line = Colors.white.withValues(alpha: 0.7);
    return SizedBox(
      width: 170,
      height: 18,
      child: Row(
        children: [
          for (var i = 0; i < done.length; i++) ...[
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done[i] ? Colors.white : Colors.transparent,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            if (i != done.length - 1)
              Expanded(child: Container(height: 2, color: line)),
          ],
        ],
      ),
    );
  }
}
