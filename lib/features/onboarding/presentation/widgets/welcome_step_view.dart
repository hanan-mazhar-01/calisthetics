import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/bunny_image.dart';
import '../../../../shared/widgets/media_placeholder.dart';
import '../../../../shared/widgets/primary_button.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_modal_sheet.dart';
import 'account_ready_dialog.dart';
import 'intro_motion.dart';
import 'typewriter_text.dart';
import '../../../sync/presentation/providers/sync_providers.dart';

/// Screen 1: full-bleed dark cover — the only onboarding screen with no
/// chrome header, matching the reference's cinematic first impression.
class WelcomeStepView extends ConsumerStatefulWidget {
  const WelcomeStepView({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  ConsumerState<WelcomeStepView> createState() => _WelcomeStepViewState();
}

class _WelcomeStepViewState extends ConsumerState<WelcomeStepView>
    with SingleTickerProviderStateMixin {
  /// Starts when the headline has been typed: the rest comes in under it.
  late final AnimationController _body = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  bool _signingIn = false;

  /// "Log in": an account with a finished plan goes straight home with its
  /// data. A new account (or one without a plan yet) gets the "account is
  /// ready" popup, whose "Get started" continues into onboarding.
  Future<void> _logIn() async {
    if (_signingIn) return;
    final router = GoRouter.of(context);
    final session = ref.read(accountSessionProvider);
    if (ref.read(authRepositoryProvider).currentUser == null) {
      final ok = await showAuthModalSheet(context, initialIsSignUp: false);
      if (ok != true || !mounted) return;
    }
    setState(() => _signingIn = true);
    final bool home;
    try {
      home = await session.afterSignIn();
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
    if (!mounted) return;
    if (home) {
      router.go('/home');
      return;
    }
    final user = ref.read(authRepositoryProvider).currentUser;
    await showAccountReadyDialog(
      context,
      isNew: _isNewAccount(user),
      email: user?.email,
    );
    if (mounted) widget.onStart();
  }

  /// Made just now (sign-up, or a first Google/Apple sign-in).
  static bool _isNewAccount(User? user) {
    final made = user?.metadata.creationTime;
    final last = user?.metadata.lastSignInTime;
    if (made == null || last == null) return true;
    return last.difference(made).abs() < const Duration(minutes: 2);
  }

  void _typed() {
    if (!mounted) return;
    MediaQuery.disableAnimationsOf(context) ? _body.value = 1 : _body.forward();
  }

  @override
  Widget build(BuildContext context) {
    final p = _WelcomePalette.of(context);
    final user = ref.watch(currentUserProvider);
    final signedIn = user != null;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [p.bgTop, p.bg],
              stops: const [0, 0.5],
            ),
          ),
        ),
        // The photo fills the top half; the gradient below fades it into the
        // cover colour before the headline starts.
        // Full width, so the picture's own edges are the screen's edges (no
        // visible cut-off sides); the gradient below fades its lower part
        // into the background before the headline.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AspectRatio(
            aspectRatio: 937 / 1678,
            child: BunnyImage(
              'onboarding/welcome-hero',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              fallback: const Opacity(
                opacity: 0.3,
                child: MediaPlaceholder(
                  brief: 'Four women in colourful workout outfits, arms raised, stretching',
                ),
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                p.topScrim,
                p.bg.withValues(alpha: 0),
                p.bg.withValues(alpha: 0.88),
                p.bg,
              ],
              stops: const [0, 0.2, 0.5, 0.7],
            ),
          ),
        ),
        // The name line sits at the very top, over the photo, on a soft pill
        // so it reads on any picture.
        Positioned(
          top: MediaQuery.paddingOf(context).top + 14,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: p.bg.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'CALESTHETICS FOR WOMEN',
                style: AppTypography.kicker(p.accent, letterSpacingEm: 0.14),
              ),
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.xxxl,
          right: AppSpacing.xxxl,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TypewriterText(
                onDone: _typed,
                style: AppTypography.display(
                  fontSize: 42,
                  color: p.fg,
                  stretchPercent: 78,
                ),
                segments: [
                  const TypeSegment('Build strength.\n'),
                  TypeSegment('Master', AppTypography.accentSerif(p.accent)),
                  const TypeSegment(' your body.'),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              IntroReveal(
                animation: _body,
                from: 0,
                to: 0.4,
                child: Text(
                  'Four-week plans that build from the basics toward real calisthenics skills, one phase at a time.',
                  style: AppTypography.body(p.body),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              IntroReveal(
                animation: _body,
                from: 0.15,
                to: 0.55,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: p.fg.withValues(alpha: 0.18)),
                      bottom: BorderSide(color: p.fg.withValues(alpha: 0.18)),
                    ),
                  ),
                  child: Row(
                    children: const [
                      _Stat(value: '8', caption: 'Skills'),
                      SizedBox(width: AppSpacing.xxxl),
                      _Stat(value: '115', caption: 'Exercises'),
                      SizedBox(width: AppSpacing.xxxl),
                      _Stat(value: '98', caption: 'Coached videos'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              IntroReveal(
                animation: _body,
                from: 0.35,
                to: 0.8,
                child: PrimaryButton(
                  label: 'Start my journey',
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: widget.onStart,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _LoginLink(
                palette: p,
                busy: _signingIn,
                signedInAs: signedIn ? (user.email ?? 'your account') : null,
                onTap: _logIn,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Already training with us? Log in", or, once signed in on this screen,
/// "Signed in as ... Continue" (never a second sign-in on top of the first).
class _LoginLink extends StatelessWidget {
  const _LoginLink({
    required this.palette,
    required this.busy,
    required this.signedInAs,
    required this.onTap,
  });

  final _WelcomePalette palette;
  final bool busy;
  final String? signedInAs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final strong = TextStyle(color: p.fg, fontWeight: FontWeight.w600);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: busy
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: p.accent,
                ),
              )
            : Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  style: AppTypography.body(p.muted, fontSize: 14),
                  children: signedInAs == null
                      ? [
                          const TextSpan(text: 'Already training with us? '),
                          TextSpan(text: 'Log in', style: strong),
                        ]
                      : [
                          TextSpan(text: 'Signed in as $signedInAs \u00b7 '),
                          TextSpan(text: 'Continue', style: strong),
                        ],
                ),
              ),
      ),
    );
  }
}

/// Colours of the welcome screen: light in the light theme (soft rose wash,
/// dark text), the dark cover in the dark theme.
class _WelcomePalette {
  const _WelcomePalette({
    required this.bgTop,
    required this.bg,
    required this.topScrim,
    required this.fg,
    required this.body,
    required this.muted,
    required this.accent,
  });

  final Color bgTop;
  final Color bg;
  final Color topScrim;
  final Color fg;
  final Color body;
  final Color muted;
  final Color accent;

  factory _WelcomePalette.of(BuildContext context) {
    final c = context.appColors;
    if (Theme.of(context).brightness == Brightness.light) {
      return _WelcomePalette(
        bgTop: c.softRose,
        bg: c.background,
        topScrim: c.background.withValues(alpha: 0),
        fg: c.textPrimary,
        body: c.textSecondary,
        muted: c.textSecondary,
        accent: c.accentText,
      );
    }
    return _WelcomePalette(
      bgTop: c.cover,
      bg: c.cover,
      topScrim: c.scrim(0.25),
      fg: c.onCover,
      body: c.onCoverTertiary,
      muted: c.onCoverSecondary,
      accent: c.coverAccent,
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.caption});

  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final p = _WelcomePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.title(22, p.fg, weight: FontWeight.w800),
        ),
        Text(caption, style: AppTypography.body(p.muted, fontSize: 12)),
      ],
    );
  }
}
