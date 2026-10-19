import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/motion/calesthetics_motion.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_reveal.dart';
import '../../../auth/domain/auth_failure.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_modal_sheet.dart';
import '../../../media/data/exercise_videos.dart';
import '../../../paywall/data/subscription_service.dart';
import '../../../paywall/domain/subscription.dart';
import '../../../paywall/presentation/providers/subscription_providers.dart';
import '../../../paywall/presentation/widgets/subscription_pill.dart';
import '../../../onboarding/presentation/providers/onboarding_controller.dart';
import '../../../plan/presentation/widgets/plan_confirm_dialog.dart';
import '../../../sync/presentation/providers/sync_providers.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../widgets/reminder_sheet.dart';

const _supportEmail = 'support@veradostudio.com';

/// Profile tab: account, plan status and the app's settings, in the same
/// flat white cards as the rest of the app.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final user = ref.watch(currentUserProvider);
    final name = ref.watch(onboardingControllerProvider.select((s) => s.name));
    final settings = ref.watch(settingsProvider);
    final subscription = ref.watch(subscriptionProvider);
    final planCount = ref.watch(ownedPlansProvider).length;
    final reminder = settings['reminderTime'] as String?;
    final reminderOn = settings['reminderEnabled'] == true;

    Duration d(int step) => Duration(milliseconds: 70 * step);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.paddingOf(context).bottom + 20,
          ),
          children: [
            _Enter(
              delay: d(0),
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 20),
                child: Text(
                  'My Profile',
                  textAlign: TextAlign.center,
                  style: AppTypography.title(
                    22,
                    c.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            _Enter(
              delay: d(1),
              child: _AccountCard(
                name: name.trim(),
                user: user,
                status: subscription,
                onEdit: () => _editName(context, ref),
                onConnect: () => _connect(context, ref),
              ),
            ),
            const SizedBox(height: 14),
            _Enter(
              delay: d(2),
              child: _AppearanceTabs(
                mode: (settings['themeMode'] as String?) ?? 'light',
                onChanged: (v, origin) => ThemeReveal.run(
                  origin,
                  () => ref.read(settingsProvider.notifier).set('themeMode', v),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Enter(
              delay: d(2),
              child: _PlanCard(
                status: subscription,
                planCount: planCount,
                onUpgrade: () => context.push('/paywall'),
                onManage: () => _manageSubscription(context, ref),
              ),
            ),
            const SizedBox(height: 16),
            ..._rows(context, ref, [
              _RowData(
                icon: Icons.notifications_none_rounded,
                title: 'Reminders',
                subtitle: 'On the days your plan trains',
                value: reminderOn && reminder != null
                    ? _format(context, reminder)
                    : 'Off',
                onTap: () => showReminderSheet(context),
              ),
              _RowData(
                icon: Icons.download_done_rounded,
                title: 'Downloaded videos',
                subtitle: 'Saved after the first play, for offline use',
                value: 'Clear',
                onTap: () => _clearVideos(context),
              ),
              _RowData(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                value: _supportEmail,
                onTap: () async {
                  await Clipboard.setData(
                    const ClipboardData(text: _supportEmail),
                  );
                  if (context.mounted) {
                    _snack(context, 'Email address copied');
                  }
                },
              ),
              _RowData(
                icon: Icons.shield_outlined,
                title: 'Privacy Policy',
                onTap: () => context.push('/privacy'),
              ),
              _RowData(
                icon: Icons.description_outlined,
                title: 'Terms of Use',
                onTap: () => context.push('/terms'),
              ),
              if (user != null)
                _RowData(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  value: user.email ?? 'Connected',
                  onTap: () => _confirmSignOut(context, ref),
                )
              else
                _RowData(
                  icon: Icons.login_rounded,
                  title: 'Sign in / Sign up',
                  value: 'Connect account',
                  onTap: () => _connect(context, ref),
                ),
              _RowData(
                icon: Icons.delete_outline_rounded,
                title: 'Delete Account',
                destructive: true,
                onTap: () => _confirmDelete(context, ref),
              ),
            ]),
            const SizedBox(height: 10),
            _Enter(
              delay: d(9),
              child: Center(
                child: Text(
                  'Calesthetics 1.0.0',
                  style: AppTypography.body(c.textMuted, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One rounded card per row, each fading in a little after the last.
  List<Widget> _rows(BuildContext context, WidgetRef ref, List<_RowData> rows) {
    return [
      for (var i = 0; i < rows.length; i++)
        _Enter(
          delay: Duration(milliseconds: 70 * (3 + i)),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _Row(data: rows[i]),
          ),
        ),
    ];
  }

  static String _format(BuildContext context, String hhmm) {
    final p = hhmm.split(':');
    if (p.length != 2) return hhmm;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return hhmm;
    return TimeOfDay(hour: h, minute: m).format(context);
  }

  static void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  static Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final current = ref.read(onboardingControllerProvider).name;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: current),
    );
    if (result == null) return;
    ref.read(onboardingControllerProvider.notifier).setName(result.trim());
  }

  static Future<void> _clearVideos(BuildContext context) async {
    final ok = await showPlanConfirmDialog(
      context,
      title: 'Clear downloaded videos?',
      message:
          'Exercise videos saved on this phone are removed. They download '
          'again the next time they play.',
      confirmLabel: 'Clear',
    );
    if (!ok || !context.mounted) return;
    await ExerciseVideos.clearSaved();
    if (context.mounted) _snack(context, 'Downloaded videos cleared.');
  }

  static Future<void> _connect(BuildContext context, WidgetRef ref) async {
    final ok = await showAuthModalSheet(context);
    if (ok != true || !context.mounted) return;
    final router = GoRouter.of(context);
    // An existing account brings its own data; if that account never
    // finished onboarding, continue it there.
    final home = await ref.read(accountSessionProvider).afterSignIn();
    if (!home) router.go('/');
  }

  static Future<void> _manageSubscription(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final service = ref.read(subscriptionServiceProvider);
    final status = ref.read(subscriptionProvider);
    final other = status.plan == PremiumPlan.yearly ? 'Monthly' : 'Yearly';
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final c = context.appColors;
        Widget item(
          String id,
          IconData icon,
          String label, {
          bool red = false,
        }) => ListTile(
          leading: Icon(icon, color: red ? Colors.red.shade700 : c.accentText),
          title: Text(
            label,
            style: AppTypography.title(
              15,
              red ? Colors.red.shade700 : c.textPrimary,
              weight: FontWeight.w600,
            ),
          ),
          onTap: () => Navigator.pop(context, id),
        );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 18, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your subscription',
                  style: AppTypography.title(
                    18,
                    c.textPrimary,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                item('change', Icons.swap_horiz_rounded, 'Switch to $other'),
                item('restore', Icons.refresh_rounded, 'Restore purchases'),
                if (service.canCancelInApp)
                  item(
                    'cancel',
                    Icons.cancel_outlined,
                    'Cancel subscription (test mode)',
                    red: true,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'To cancel, open your App Store or Google Play subscriptions.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body(c.textSecondary, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (!context.mounted || choice == null) return;
    final notifier = ref.read(subscriptionProvider.notifier);
    switch (choice) {
      case 'change':
        context.push('/paywall');
      case 'restore':
        final s = await notifier.restore();
        if (context.mounted) {
          _snack(
            context,
            s.isPremium
                ? 'Your Premium is active.'
                : 'No active subscription was found.',
          );
        }
      case 'cancel':
        final ok = await showPlanConfirmDialog(
          context,
          title: 'Cancel Premium?',
          message:
              'You go back to Free: one plan, and Discover videos lock again.',
          confirmLabel: 'Cancel it',
        );
        if (ok) await notifier.cancel();
    }
  }

  static Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final signedIn = ref.read(authRepositoryProvider).currentUser != null;
    final ok = await showPlanConfirmDialog(
      context,
      title: 'Delete account?',
      message: signedIn
          ? 'Your account and everything in it (plans, history, favorites, '
                'records and settings) are deleted from our servers and this '
                'phone. It cannot be undone. If you signed in a while ago, '
                'you will be asked to confirm it is you first.'
          : 'This erases your plan, history, favorites and settings from this '
                'phone and takes you back to the start. It cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!ok || !context.mounted) return;
    final router = GoRouter.of(context);
    try {
      await ref
          .read(accountSessionProvider)
          .deleteAccount(
            askPassword: () => showDialog<String>(
              context: context,
              builder: (_) => const _NameDialog.password(),
            ),
          );
    } on AuthFailure catch (e) {
      if (context.mounted) _snack(context, e.message);
      return;
    }
    router.go('/');
  }

  static Future<void> _confirmSignOut(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ok = await showPlanConfirmDialog(
      context,
      title: 'Sign out?',
      message:
          'Your plan and progress stay saved in your account. Sign in again '
          'to get them back.',
      confirmLabel: 'Sign out',
    );
    if (!ok || !context.mounted) return;
    final router = GoRouter.of(context);
    await ref.read(accountSessionProvider).signOut();
    router.go('/');
  }
}

/// Entrance: fade + slide, skipped when animations are disabled.
class _Enter extends StatelessWidget {
  const _Enter({required this.child, required this.delay});
  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return CalestheticsFadeSlide(delay: delay, offset: 14, child: child);
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.name,
    this.user,
    required this.status,
    required this.onEdit,
    required this.onConnect,
  });

  final String name;
  final User? user;
  final SubscriptionStatus status;
  final VoidCallback onEdit;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (name.isNotEmpty ? name : 'Athlete');
    final initial = displayName.characters.first.toUpperCase();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.divider),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 6,
            right: 6,
            child: IconButton(
              tooltip: 'Edit name',
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, color: c.accentText, size: 22),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
              child: Column(
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.softRose,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.accent, width: 2.5),
                    ),
                    child: Text(
                      initial,
                      style: AppTypography.title(
                        40,
                        c.accentText,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.title(
                      26,
                      c.textPrimary,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user != null
                        ? (user!.email ?? 'Account connected')
                        : 'Guest · saved on this device',
                    textAlign: TextAlign.center,
                    style: AppTypography.body(c.textMuted, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  SubscriptionPill(status: status),
                  if (user == null) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: c.accent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                      ),
                      onPressed: onConnect,
                      icon: Icon(
                        Icons.login_rounded,
                        size: 18,
                        color: c.accentText,
                      ),
                      label: Text(
                        'Sign in / Create account',
                        style: AppTypography.title(
                          14,
                          c.accentText,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Light / Dark / Auto as tabs, in the style of the All / Month / Week strip.
class _AppearanceTabs extends StatelessWidget {
  const _AppearanceTabs({required this.mode, required this.onChanged});
  final String mode;
  final void Function(String mode, Offset origin) onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    const options = [('light', 'Light'), ('dark', 'Dark'), ('system', 'Auto')];
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Row(
        children: [
          for (final (id, label) in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: mode == id,
                label: 'Appearance: $label',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) {
                    if (id != mode) onChanged(id, d.globalPosition);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 52,
                    alignment: Alignment.center,
                    color: mode == id ? c.surface : c.surfaceMuted,
                    child: Text(
                      label,
                      style: AppTypography.body(
                        mode == id ? c.textPrimary : c.textMuted,
                        fontSize: 16,
                        weight: mode == id ? FontWeight.w700 : FontWeight.w500,
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
}

/// Free: what Premium adds and an Upgrade button. Premium: the plan, its
/// trial days or renewal date, and Manage.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.status,
    required this.planCount,
    required this.onUpgrade,
    required this.onManage,
  });

  final SubscriptionStatus status;
  final int planCount;
  final VoidCallback onUpgrade;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final now = DateTime.now();
    final premium = status.isPremium;
    final fg = premium ? Colors.white : c.textPrimary;
    final fg2 = premium
        ? Colors.white.withValues(alpha: 0.88)
        : c.textSecondary;
    final plan = status.plan == PremiumPlan.yearly ? 'Yearly' : 'Monthly';
    final price = status.plan == PremiumPlan.yearly
        ? r'$49.99/year'
        : r'$9.99/month';
    final days = status.trialDaysLeft(now);
    final kicker = !premium
        ? 'YOUR PLAN'
        : status.inTrial
        ? 'PREMIUM · FREE TRIAL'
        : 'PREMIUM';
    final title = !premium
        ? 'Free'
        : status.inTrial
        ? '$days ${days == 1 ? 'day' : 'days'} left'
        : '$plan · Active';
    final renew = status.renewsAt == null
        ? null
        : formatShortDate(status.renewsAt!);
    final text = !premium
        ? '1 plan included${planCount > 0 ? ' ($planCount in use)' : ''}. '
              'Upgrade to unlock every plan and all exercises.'
        : status.inTrial
        ? 'Then $price. Cancel any time before it ends.'
        : !status.willRenew && renew != null
        ? 'Ends on $renew.'
        : renew != null
        ? '$price. Renews on $renew.'
        : price;

    return Semantics(
      button: true,
      label: '$kicker. $title. $text',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: premium ? onManage : onUpgrade,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: premium ? null : c.surface,
            gradient: premium
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF8FA5),
                      const Color(0xFFEF5B82),
                      c.accent,
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(24),
            border: premium ? null : Border.all(color: c.divider),
            boxShadow: [
              if (premium)
                BoxShadow(
                  color: const Color(0xFFEF5B82).withValues(alpha: 0.3),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kicker,
                      style: AppTypography.kicker(fg2, letterSpacingEm: 0.14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: AppTypography.title(
                        20,
                        fg,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      text,
                      style: AppTypography.body(fg2, fontSize: 13, height: 1.4),
                    ),
                    if (status.inTrial) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (1 - days / LocalSubscriptionService.trialDays)
                              .clamp(0.05, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          color: Colors.white,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: premium
                            ? Colors.white.withValues(alpha: 0.22)
                            : c.accent,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        premium ? 'Manage' : 'Upgrade',
                        style: AppTypography.title(
                          13.5,
                          premium ? Colors.white : c.onAccent,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.workspace_premium_rounded,
                size: 54,
                color: premium
                    ? Colors.white.withValues(alpha: 0.35)
                    : c.softRose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowData {
  const _RowData({
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
}

class _Row extends StatefulWidget {
  const _Row({required this.data});
  final _RowData data;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final data = widget.data;
    final enabled = data.onTap != null;
    final titleColor = data.destructive
        ? c.warning
        : (enabled ? c.textPrimary : c.textMuted);
    return Semantics(
      button: enabled,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: data.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _pressed ? c.surfaceMuted : c.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Icon(
                  data.icon,
                  size: 24,
                  color: data.destructive ? c.warning : c.accentText,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: AppTypography.title(
                        16,
                        titleColor,
                        weight: FontWeight.w600,
                      ),
                    ),
                    if (data.subtitle != null)
                      Text(
                        data.subtitle!,
                        style: AppTypography.body(c.textMuted, fontSize: 12.5),
                      ),
                  ],
                ),
              ),
              // The value sits right against the chevron, like in every row.
              if (data.value != null) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    data.value!,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(c.textMuted, fontSize: 14),
                  ),
                ),
              ],
              if (enabled) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: c.textMuted, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial}) : password = false;

  /// Asks for the account password before the account is deleted.
  const _NameDialog.password() : initial = '', password = true;

  final String initial;
  final bool password;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    Widget button(String label, VoidCallback onTap, {bool primary = false}) =>
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary ? c.accent : c.surfaceMuted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: AppTypography.title(
                  16,
                  primary ? c.onAccent : c.textPrimary,
                  weight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
    return Dialog(
      backgroundColor: c.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.password ? 'Confirm your password' : 'Your name',
              style: AppTypography.title(
                22,
                c.textPrimary,
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _ctrl,
              autofocus: true,
              obscureText: widget.password,
              keyboardType: widget.password
                  ? TextInputType.visiblePassword
                  : TextInputType.name,
              textCapitalization: widget.password
                  ? TextCapitalization.none
                  : TextCapitalization.words,
              textInputAction: TextInputAction.done,
              maxLength: widget.password ? null : 40,
              style: AppTypography.body(c.textPrimary, fontSize: 17),
              decoration: InputDecoration(
                hintText: widget.password ? 'Password' : 'First name',
                counterText: '',
                filled: true,
                fillColor: c.surfaceMuted,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (v) => Navigator.of(context).pop(v),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                button('Cancel', () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                button(
                  widget.password ? 'Delete' : 'Save',
                  () => Navigator.of(context).pop(_ctrl.text),
                  primary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
