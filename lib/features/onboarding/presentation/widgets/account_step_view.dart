import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/dots_loader.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/google_logo.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/domain/apple_sign_in.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_modal_sheet.dart';

import 'package:go_router/go_router.dart';

import '../../../sync/presentation/providers/sync_providers.dart';

/// Optional account creation step at the end of onboarding.
/// Connects to Apple, Google, or Email Authentication via Firebase.
class AccountStepView extends ConsumerStatefulWidget {
  const AccountStepView({
    super.key,
    required this.onSkip,
    required this.onBack,
    this.busy = false,
  });

  final VoidCallback onSkip;
  final VoidCallback onBack;

  /// True while the plan is being started.
  final bool busy;

  @override
  ConsumerState<AccountStepView> createState() => _AccountStepViewState();
}

class _AccountStepViewState extends ConsumerState<AccountStepView> {
  /// The row that was tapped: only it shows the loader.
  String? _active;

  Future<void> _handleGoogle() async {
    final ctl = ref.read(authControllerProvider.notifier);
    setState(() => _active = 'google');
    final user = await ctl.signInWithGoogle();
    if (mounted) setState(() => _active = null);
    if (user != null) await _signedIn();
  }

  Future<void> _handleApple() async {
    final ctl = ref.read(authControllerProvider.notifier);
    setState(() => _active = 'apple');
    final user = await ctl.signInWithApple();
    if (mounted) setState(() => _active = null);
    if (user != null) await _signedIn();
  }

  Future<void> _handleEmail() async {
    final success = await showAuthModalSheet(context, initialIsSignUp: true);
    if (success == true) await _signedIn();
  }

  /// An existing account with a finished plan goes straight home with its
  /// own data; a new account keeps what was answered so far and continues.
  Future<void> _signedIn() async {
    final home = await ref.read(accountSessionProvider).afterSignIn();
    if (!mounted) return;
    if (home) {
      context.go('/home');
    } else {
      widget.onSkip();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final authState = ref.watch(authControllerProvider);
    final isBusy = widget.busy || authState.isLoading;

    ref.listen(authControllerProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.red.shade800,
            ),
          );
      }
    });

    final methods =
        <({String id, Widget icon, String label, VoidCallback onTap})>[
          if (appleSignInAvailable)
            (
              id: 'apple',
              icon: Icon(Icons.apple_rounded, color: c.textPrimary, size: 22),
              label: 'Continue with Apple',
              onTap: _handleApple,
            ),
          (
            id: 'google',
            // Google's own mark, as its branding rules ask.
            icon: const GoogleLogo(size: 22),
            label: 'Continue with Google',
            onTap: _handleGoogle,
          ),
          (
            id: 'email',
            icon: Icon(
              Icons.mail_outline_rounded,
              color: c.textPrimary,
              size: 22,
            ),
            label: 'Continue with email',
            onTap: _handleEmail,
          ),
        ];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GlassButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: 'Back',
                      onPressed: isBusy ? null : widget.onBack,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: isBusy ? null : widget.onSkip,
                      child: Text(
                        'Skip',
                        style: AppTypography.title(
                          16,
                          c.accentText,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  'Save your plan.',
                  style: AppTypography.display(
                    fontSize: 36,
                    color: c.textPrimary,
                    stretchPercent: 82,
                    height: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'An account keeps your customized plan, streak, and progress safe if you change devices.',
                  style: AppTypography.body(c.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                for (final item in methods)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: isBusy ? null : item.onTap,
                      child: GlassCard(
                        child: Row(
                          children: [
                            item.icon,
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Text(
                                item.label,
                                style: AppTypography.title(
                                  16,
                                  c.textPrimary,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isBusy && _active == item.id)
                              DotsLoader(color: c.accentText, dot: 6)
                            else
                              Icon(
                                Icons.chevron_right_rounded,
                                color: c.textMuted,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Creating an account is optional. You can also skip and connect it later in your profile.',
                  style: AppTypography.body(c.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxxl,
            0,
            AppSpacing.xxxl,
            AppSpacing.xxl,
          ),
          child: PrimaryButton(
            label: 'Skip and start my plan',
            enabled: !isBusy,
            onPressed: isBusy ? null : widget.onSkip,
            trailingIcon: Icons.arrow_forward_rounded,
          ),
        ),
      ],
    );
  }
}
