import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/app_background.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../domain/plan_timeline.dart';
import '../../../plans/domain/plan_builder.dart';
import '../../../plans/domain/plan_template.dart';
import '../../../user/domain/active_plan.dart';
import '../../../plans/domain/user_profile.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../providers/plan_settings_draft.dart';
import '../widgets/plan_confirm_dialog.dart';
import 'plan_option_edit_screen.dart';

/// "Current Plan Settings": edit focus, level, duration and areas to avoid,
/// then apply them to the running plan. Also holds the voice-guidance
/// choices. Sessions are rebuilt from the new preferences, so the exercises
/// (and therefore videos) follow the settings.
class PlanSettingsScreen extends ConsumerWidget {
  const PlanSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final draft = ref.watch(planDraftProvider);
    final template = ref.watch(activeTemplateProvider);
    final conflicts =
        template?.conflictsWith(draft.protectedAreas) ??
        const <ProtectedArea>{};
    final unusable = const PlanBuilder().unusableFocusAreas(draft);

    return GradientScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.md,
            AppSpacing.xxl,
            AppSpacing.xxxl,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Back',
                onPressed: () => context.pop(),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: c.textPrimary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Current Plan Settings',
              style: AppTypography.title(
                22,
                c.textPrimary,
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            GlassCard(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                children: [
                  _SettingRow(
                    label: 'Focus',
                    value: summarize([
                      for (final id in focusLabels.keys)
                        if (draft.focusAreas.contains(id)) focusLabels[id]!,
                    ]),
                    onTap: () => _edit(context, PlanOption.focus),
                  ),
                  _SettingRow(
                    label: 'Workout Level',
                    value: levelLabel(draft.level),
                    onTap: () => _edit(context, PlanOption.level),
                  ),
                  _SettingRow(
                    label: 'Duration',
                    value: durationLabel(draft.sessionMinutes),
                    onTap: () => _edit(context, PlanOption.duration),
                  ),
                  _SettingRow(
                    label: 'Avoid Areas',
                    value: summarize([
                      for (final a in ProtectedArea.values)
                        if (draft.protectedAreas.contains(a)) areaLabel(a),
                    ]),
                    onTap: () => _edit(context, PlanOption.avoid),
                    last: true,
                  ),
                  if (conflicts.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'This plan loads your ${conflicts.map((a) => areaLabel(a).toLowerCase()).join(', ')}. '
                      'We swap out what we can, but another plan may suit you better.',
                      style: AppTypography.body(c.textSecondary, fontSize: 13),
                    ),
                  ],
                  if (unusable.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Your avoid areas leave no exercises for '
                      '${unusable.map((id) => focusLabels[id]!.toLowerCase()).join(', ')}, '
                      'so that focus can’t be used. Change one of them to see it in your plan.',
                      style: AppTypography.body(c.textSecondary, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _FilledButton(
                    label: 'UPDATE MY CURRENT PLAN',
                    onTap: () => _update(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _OutlineButton(
                    label: 'Restart From Day1',
                    onTap: () => _restart(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Sounds',
              style: AppTypography.title(
                20,
                c.textPrimary,
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SoundsCard(),
          ],
        ),
      ),
    );
  }

  Future<void> _update(BuildContext context, WidgetRef ref) async {
    final draft = ref.read(planDraftProvider);
    final plan = ref.read(activePlanProvider);
    final template = ref.read(activeTemplateProvider);
    final changes = (plan == null || template == null)
        ? null
        : _changeSummary(template, plan, draft);
    final ok = await showPlanConfirmDialog(
      context,
      title: 'Update your plan?',
      message:
          'Your workouts will be rebuilt around your new focus, level, '
          'duration and areas to avoid. Your history and progress are kept.',
      detail: changes?.dialogText,
      confirmLabel: 'Update',
    );
    if (!ok || !context.mounted) return;
    await ref.read(activePlanProvider.notifier).updateProfile(draft);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(changes?.snackText ?? 'Plan updated')),
    );
    context.pop();
  }

  /// Compares the next four weeks before and after the edit, so she can see
  /// what the preferences did to her exercises.
  _Changes _changeSummary(PlanTemplate t, ActivePlan plan, UserProfile next) {
    const builder = PlanBuilder();
    int stageFor(UserProfile p) => p.level != plan.profile.level
        ? builder.startingStage(t, p)
        : plan.stageIndex;
    String sig(BuiltSession s) =>
        '${s.warmUp}${s.coolDown}${s.items.map((i) => '${i.exerciseNumber}x${i.sets}')}';
    var days = 0;
    var changed = 0;
    for (var w = 1; w <= 4; w++) {
      final skip = w == 1 ? PlanTimeline.leadingSkip(plan) : 0;
      final before = builder.buildWeek(
        t,
        plan.profile,
        week: w,
        stageIndex: plan.stageIndex,
        skipLeadingDays: skip,
      );
      final after = builder.buildWeek(
        t,
        next,
        week: w,
        stageIndex: stageFor(next),
        skipLeadingDays: skip,
      );
      for (var d = 0; d < 7; d++) {
        final a = after.days[d].session;
        final b = before.days[d].session;
        if (a == null && b == null) continue;
        days++;
        if (a == null || b == null || sig(a) != sig(b)) changed++;
      }
    }
    return _Changes(changed, days);
  }

  Future<void> _restart(BuildContext context, WidgetRef ref) async {
    final ok = await showPlanConfirmDialog(
      context,
      title: 'Restart from Day 1?',
      message:
          'Your plan starts again from Day 1, beginning today, with the '
          'preferences you have set here. Your workout history is kept.',
      confirmLabel: 'Restart',
    );
    if (!ok || !context.mounted) return;
    await ref
        .read(activePlanProvider.notifier)
        .updateProfile(ref.read(planDraftProvider));
    await ref.read(activePlanProvider.notifier).restart();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Plan restarted from Day 1')));
    context.pop();
  }

  void _edit(BuildContext context, PlanOption option) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlanOptionEditScreen(option: option),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.last = false,
  });
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      label: '$label, $value',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            border: last
                ? null
                : Border(
                    bottom: BorderSide(color: c.divider.withValues(alpha: 0.7)),
                  ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: AppTypography.title(
                  17,
                  c.textPrimary,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppTypography.body(
                    c.textMuted,
                    fontSize: 16,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilledButton extends StatelessWidget {
  const _FilledButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.accent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: AppTypography.title(16, c.onAccent, weight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: c.accent, width: 1.6),
          ),
          child: Text(
            label,
            style: AppTypography.title(
              16,
              c.accentText,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

/// Sounds: just a Music on/off switch (saved in settings as `musicEnabled`).
class _SoundsCard extends ConsumerWidget {
  const _SoundsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final on = (ref.watch(settingsProvider)['musicEnabled'] as bool?) ?? true;
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Music',
              style: AppTypography.title(
                17,
                c.textPrimary,
                weight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: on,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).set('musicEnabled', v),
          ),
        ],
      ),
    );
  }
}

/// How many of the next four weeks' workouts an edit changes.
class _Changes {
  const _Changes(this.changed, this.total);
  final int changed;
  final int total;

  String get dialogText => changed == 0
      ? 'None of your exercises are affected by this change.'
      : 'Exercises change in $changed of $total workouts.';

  String get snackText => changed == 0
      ? 'Plan updated — no exercise in this plan is affected by that change'
      : 'Plan updated — exercises changed in $changed of $total workouts';
}
