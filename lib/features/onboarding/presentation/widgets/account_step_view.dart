import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_modal_sheet.dart';

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
  Future<void> _handleGoogle() async {
    final ctl = ref.read(authControllerProvider.notifier);
    final user = await ctl.signInWithGoogle();
    if (user != null && mounted) {
      widget.onSkip();
    }
  }

  Future<void> _handleApple() async {
    final ctl = ref.read(authControllerProvider.notifier);
    final user = await ctl.signInWithApple();
    if (user != null && mounted) {
      widget.onSkip();
    }
  }

  Future<void> _handleEmail() async {
    final success = await showAuthModalSheet(
      context,
      initialIsSignUp: true,
    );
    if (success == true && mounted) {
      widget.onSkip();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final authState = ref.watch(authControllerProvider);
    final isBusy = widget.busy || authState.isLoading;

    ref.listen(authControllerProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
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

    final methods = [
      (
        icon: Icons.apple_rounded,
        label: 'Continue with Apple',
        onTap: _handleApple,
      ),
      (
        icon: Icons.g_mobiledata_rounded,
        label: 'Continue with Google',
        onTap: _handleGoogle,
      ),
      (
        icon: Icons.mail_outline_rounded,
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
                            Icon(
                              item.icon,
                              color: c.textPrimary,
                              size: item.icon == Icons.g_mobiledata_rounded ? 28 : 22,
                            ),
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
                            if (isBusy)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
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
