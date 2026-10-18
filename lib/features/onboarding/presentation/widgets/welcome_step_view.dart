import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/bunny_image.dart';
import '../../../../shared/widgets/media_placeholder.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/widgets/auth_modal_sheet.dart';
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

  void _typed() {
    if (!mounted) return;
    MediaQuery.disableAnimationsOf(context) ? _body.value = 1 : _body.forward();
  }

  @override
  Widget build(BuildContext context) {
    final p = _WelcomePalette.of(context);
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
        Positioned(
          left: AppSpacing.xxxl,
          right: AppSpacing.xxxl,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(width: 22, height: 2, color: p.accent),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    "CALESTHETICS FOR WOMEN",
                    style: AppTypography.kicker(
                      p.accent,
                      letterSpacingEm: 0.14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
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
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final success = await showAuthModalSheet(
                    context,
                    initialIsSignUp: false,
                  );
                  if (success == true && context.mounted) {
                    // Their account's plan and progress are now on the
                    // phone; a new or unfinished account continues here.
                    final home = await ref
                        .read(accountSessionProvider)
                        .afterSignIn();
                    if (home && context.mounted) context.go('/home');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text.rich(
                    TextSpan(
                      style: AppTypography.body(p.muted, fontSize: 14),
                      children: [
                        const TextSpan(text: 'Already training with us? '),
                        TextSpan(
                          text: 'Log in',
                          style: TextStyle(
                            color: p.fg,
                            fontWeight: FontWeight.w600,
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
      ],
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
