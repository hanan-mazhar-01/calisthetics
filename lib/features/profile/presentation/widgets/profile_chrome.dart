import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/app_background.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/widgets/glass/glass_card.dart';

/// Scaffold for the pushed profile sub-screens: glass back button + title.
class SubScreenScaffold extends StatelessWidget {
  const SubScreenScaffold({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GradientScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxxl,
            AppSpacing.lg,
            AppSpacing.xxxl,
            AppSpacing.xxxl,
          ),
          children: [
            Row(
              children: [
                GlassButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.title(22, c.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            ...children,
          ],
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xxxl,
        bottom: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: AppTypography.kicker(c.textSecondary),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A calm empty-state card.
class EmptyCard extends StatelessWidget {
  const EmptyCard(this.message, {super.key, this.icon = Icons.spa_outlined});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GlassCard(
      child: Row(
        children: [
          Icon(icon, color: c.textMuted),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(c.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// One finished workout row, used by Profile preview and History.
class SessionTile extends StatelessWidget {
  const SessionTile({
    super.key,
    required this.name,
    required this.when,
    required this.minutes,
    required this.exercises,
  });

  final String name;
  final String when;
  final int minutes;
  final int exercises;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: c.success),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTypography.title(15, c.textPrimary)),
                  Text(
                    '$when · $minutes min · $exercises exercises',
                    style: AppTypography.body(c.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';
