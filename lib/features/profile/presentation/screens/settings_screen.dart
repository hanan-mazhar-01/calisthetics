import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../widgets/reminder_sheet.dart';
import '../providers/profile_providers.dart';
import '../widgets/profile_chrome.dart';

const _supportEmail = 'support@veradostudio.com';

/// Settings. Account, subscription and sync are not connected yet, so those
/// rows are honest "coming soon" states, never faked.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final settings = ref.watch(settingsProvider);
    final reminder = settings['reminderTime'] as String?;

    return SubScreenScaffold(
      title: 'Settings',
      children: [
        const SectionLabel('Account'),
        const _Group([
          _Row(
            icon: Icons.login_rounded,
            title: 'Sign in or link account',
            value: 'Coming soon',
          ),
          _Row(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            value: 'Coming soon',
          ),
        ]),
        const SizedBox(height: AppSpacing.sm),
        _Group([
          _Row(
            icon: Icons.delete_outline_rounded,
            title: 'Delete account',
            subtitle: 'Erases everything stored on this device',
            destructive: true,
            onTap: () => _confirmDelete(context, ref),
          ),
        ]),
        const SectionLabel('Subscription'),
        const _Group([
          _Row(
            icon: Icons.workspace_premium_outlined,
            title: 'Subscription',
            value: 'Not connected yet',
          ),
          _Row(
            icon: Icons.restore_rounded,
            title: 'Restore purchases',
            value: 'Coming soon',
          ),
        ]),
        const SectionLabel('Training'),
        _Group([
          _Row(
            icon: Icons.alarm_rounded,
            title: 'Reminder time',
            subtitle: 'On the days your plan trains',
            value: settings['reminderEnabled'] == true
                ? (reminder ?? 'Off')
                : 'Off',
            onTap: () => showReminderSheet(context),
          ),
          _Row(
            icon: Icons.swap_horiz_rounded,
            title: 'Change plan',
            onTap: () => context.go('/home'),
          ),
          _Row(
            icon: Icons.refresh_rounded,
            title: 'Retake assessment',
            subtitle: 'Removes your plan and asks the questions again',
            onTap: () => _confirmRetake(context, ref),
          ),
          const _Row(
            icon: Icons.download_for_offline_outlined,
            title: 'Downloaded videos',
            value: 'Coming soon',
          ),
        ]),
        const SectionLabel('Appearance'),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Theme',
                  style: AppTypography.title(15, c.textPrimary),
                ),
              ),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'light', label: Text('Light')),
                  ButtonSegment(value: 'dark', label: Text('Dark')),
                  ButtonSegment(value: 'system', label: Text('Auto')),
                ],
                selected: {(settings['themeMode'] as String?) ?? 'light'},
                onSelectionChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .set('themeMode', v.first),
              ),
            ],
          ),
        ),
        const SectionLabel('About'),
        _Group([
          _Row(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _linkPlaceholder(context, 'Privacy Policy'),
          ),
          _Row(
            icon: Icons.description_outlined,
            title: 'Terms',
            onTap: () => _linkPlaceholder(context, 'Terms'),
          ),
          _Row(
            icon: Icons.mail_outline_rounded,
            title: 'Contact support',
            value: _supportEmail,
            onTap: () async {
              await Clipboard.setData(const ClipboardData(text: _supportEmail));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email address copied')),
                );
              }
            },
          ),
        ]),
      ],
    );
  }

  void _linkPlaceholder(BuildContext context, String what) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(what),
        // TODO: link the published URL once Verado Studio provides it.
        content: Text('The $what link is not available yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(
      context,
      title: 'Delete account?',
      body:
          'This erases your plan, history, favorites and settings from this '
          'device and takes you back to the start. It cannot be undone.',
      action: 'Delete',
    );
    if (ok != true || !context.mounted) return;
    final router = GoRouter.of(context);
    await ref.read(accountActionsProvider).deleteLocalData();
    router.go('/');
  }

  Future<void> _confirmRetake(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(
      context,
      title: 'Retake the assessment?',
      body:
          'Your current plan is removed. Your history, favorites and '
          'records stay.',
      action: 'Retake',
    );
    if (ok != true || !context.mounted) return;
    final router = GoRouter.of(context);
    await ref.read(accountActionsProvider).retakeAssessment();
    router.go('/');
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
  }) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
}

class _Group extends StatelessWidget {
  const _Group(this.rows);
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Divider(height: 1, indent: AppSpacing.xl, color: c.divider),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final enabled = onTap != null;
    final titleColor = destructive
        ? c.warning
        : (enabled ? c.textPrimary : c.textMuted);
    return Semantics(
      button: enabled,
      enabled: enabled,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Icon(icon, color: titleColor, size: 22),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.title(15, titleColor)),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTypography.body(
                          c.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    value!,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(c.textSecondary, fontSize: 13),
                  ),
                ),
              ],
              if (enabled) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right_rounded, color: c.textMuted, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
