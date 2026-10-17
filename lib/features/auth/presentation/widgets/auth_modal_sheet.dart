import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

/// Opens the unified Authentication sheet.
Future<bool?> showAuthModalSheet(
  BuildContext context, {
  String? initialEmail,
  bool initialIsSignUp = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => AuthModalSheet(
      initialEmail: initialEmail,
      initialIsSignUp: initialIsSignUp,
    ),
  );
}

/// A bottom sheet for sign-in and sign-up supporting Google, Apple, and Email.
class AuthModalSheet extends ConsumerStatefulWidget {
  const AuthModalSheet({
    super.key,
    this.initialEmail,
    this.initialIsSignUp = false,
  });

  final String? initialEmail;
  final bool initialIsSignUp;

  @override
  ConsumerState<AuthModalSheet> createState() => _AuthModalSheetState();
}

class _AuthModalSheetState extends ConsumerState<AuthModalSheet> {
  late bool _isSignUp = widget.initialIsSignUp;
  bool _showEmailForm = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController();
  late final TextEditingController _emailController =
      TextEditingController(text: widget.initialEmail ?? '');
  late final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSuccess() {
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _handleGoogle() async {
    final ctl = ref.read(authControllerProvider.notifier);
    final user = await ctl.signInWithGoogle();
    if (user != null) _onSuccess();
  }

  Future<void> _handleApple() async {
    final ctl = ref.read(authControllerProvider.notifier);
    final user = await ctl.signInWithApple();
    if (user != null) _onSuccess();
  }

  Future<void> _handleEmailSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final ctl = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isSignUp) {
      final name = _nameController.text.trim();
      final user = await ctl.signUpWithEmail(
        email: email,
        password: password,
        displayName: name.isEmpty ? null : name,
      );
      if (user != null) _onSuccess();
    } else {
      final user = await ctl.signInWithEmail(
        email: email,
        password: password,
      );
      if (user != null) _onSuccess();
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address to reset password.'),
        ),
      );
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(email);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset link sent to $email.'),
          backgroundColor: Colors.green.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final authState = ref.watch(authControllerProvider);
    final isBusy = authState.isLoading;

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: c.divider),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.xxl,
        bottomInset + AppSpacing.xxl,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: c.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Row
              Row(
                children: [
                  if (_showEmailForm)
                    GlassButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: 'Back to options',
                      onPressed: isBusy
                          ? null
                          : () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .clearError();
                              setState(() => _showEmailForm = false);
                            },
                    )
                  else
                    const SizedBox.shrink(),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: Icon(Icons.close_rounded, color: c.textMuted),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Title
              Text(
                _showEmailForm
                    ? (_isSignUp ? 'Create account' : 'Welcome back')
                    : (_isSignUp ? 'Join Calesthetics' : 'Sign in to Calesthetics'),
                style: AppTypography.display(
                  fontSize: 28,
                  color: c.textPrimary,
                  stretchPercent: 82,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _showEmailForm
                    ? (_isSignUp
                        ? 'Enter your details to keep your workouts synced.'
                        : 'Sign in with your email and password.')
                    : 'Save your customized plan, streak, and progress.',
                style: AppTypography.body(c.textSecondary, fontSize: 14),
              ),

              // Error banner
              if (authState.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          authState.errorMessage!,
                          style: AppTypography.body(
                            Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              if (!_showEmailForm) ...[
                // Apple Button
                _SocialButton(
                  icon: Icons.apple_rounded,
                  label: _isSignUp ? 'Sign up with Apple' : 'Continue with Apple',
                  color: Colors.black,
                  textColor: Colors.white,
                  isLoading: isBusy,
                  onPressed: isBusy ? null : _handleApple,
                ),
                const SizedBox(height: AppSpacing.md),

                // Google Button
                _SocialButton(
                  icon: Icons.g_mobiledata_rounded,
                  label: _isSignUp ? 'Sign up with Google' : 'Continue with Google',
                  color: c.surface,
                  textColor: c.textPrimary,
                  borderColor: c.divider,
                  iconSize: 28,
                  isLoading: isBusy,
                  onPressed: isBusy ? null : _handleGoogle,
                ),
                const SizedBox(height: AppSpacing.md),

                // Email Button
                _SocialButton(
                  icon: Icons.mail_outline_rounded,
                  label: _isSignUp ? 'Sign up with Email' : 'Continue with Email',
                  color: c.surface,
                  textColor: c.textPrimary,
                  borderColor: c.divider,
                  isLoading: isBusy,
                  onPressed: isBusy
                      ? null
                      : () {
                          ref
                              .read(authControllerProvider.notifier)
                              .clearError();
                          setState(() => _showEmailForm = true);
                        },
                ),

                const SizedBox(height: AppSpacing.xl),

                // Toggle Sign In / Sign Up
                Center(
                  child: TextButton(
                    onPressed: isBusy
                        ? null
                        : () {
                            ref
                                .read(authControllerProvider.notifier)
                                .clearError();
                            setState(() => _isSignUp = !_isSignUp);
                          },
                    child: Text.rich(
                      TextSpan(
                        style: AppTypography.body(c.textSecondary, fontSize: 14),
                        children: [
                          TextSpan(
                            text: _isSignUp
                                ? 'Already have an account? '
                                : "Don't have an account? ",
                          ),
                          TextSpan(
                            text: _isSignUp ? 'Sign In' : 'Sign Up',
                            style: TextStyle(
                              color: c.accentText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Email Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_isSignUp) ...[
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Your Name',
                            hintText: 'e.g. Maya',
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (v) {
                            if (_isSignUp && (v == null || v.trim().isEmpty)) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'name@example.com',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (_isSignUp && v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      if (!_isSignUp) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isBusy ? null : _handleForgotPassword,
                            child: Text(
                              'Forgot password?',
                              style: AppTypography.body(
                                c.accentText,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      PrimaryButton(
                        label: _isSignUp ? 'Create Account' : 'Sign In',
                        enabled: !isBusy,
                        onPressed: isBusy ? null : _handleEmailSubmit,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: isBusy
                            ? null
                            : () {
                                ref
                                    .read(authControllerProvider.notifier)
                                    .clearError();
                                setState(() => _isSignUp = !_isSignUp);
                              },
                        child: Text.rich(
                          TextSpan(
                            style: AppTypography.body(c.textSecondary,
                                fontSize: 14),
                            children: [
                              TextSpan(
                                text: _isSignUp
                                    ? 'Already have an account? '
                                    : "Don't have an account? ",
                              ),
                              TextSpan(
                                text: _isSignUp ? 'Sign In' : 'Sign Up',
                                style: TextStyle(
                                  color: c.accentText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    this.borderColor,
    this.iconSize = 22,
    required this.isLoading,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  final double iconSize;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          side: borderColor != null ? BorderSide(color: borderColor!) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        onPressed: isLoading ? null : onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: textColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTypography.title(15, textColor, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
