import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/motion/calesthetics_motion.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../discover/domain/discover_logic.dart';
import '../../../discover/presentation/providers/discover_providers.dart';
import '../../../discover/presentation/widgets/premium_sheet.dart';
import '../../../media/data/exercise_videos.dart';
import '../../../plans/domain/plan_builder.dart';
import '../../../workout/domain/workout_request.dart';
import '../../domain/exercise.dart';
import '../../domain/exercise_lookup.dart';
import '../widgets/exercise_chips.dart';
import '../widgets/exercise_picture.dart';

/// Full page for one catalog exercise. Content comes straight from the
/// catalog; nothing is added here.
///
/// The top shows the exercise's thumbnail (in its own 4:3 shape); nothing
/// plays on its own. The play button opens the same player as a workout
/// for a 30-second try-out.
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.number});

  /// Catalog exercise number (1–115).
  final int number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final e = exerciseByNumber(number);
    final policy = ref.watch(exerciseAccessPolicyProvider);
    final locked = !policy.canPlayVideo(e);
    final hasVideo = ExerciseVideos.exists(e);
    final nb = neighboursOf(e);

    void play() {
      if (locked) {
        showPremiumSheet(
          context,
          message:
              'All Discover exercises are part of Premium. The exercises in '
              'your free plan stay free.',
        );
        return;
      }
      context.push('/workout', extra: WorkoutRequest.demo(e.number, e.name));
    }

    // Each block rises in a little after the one above it.
    var order = 0;
    Widget enter(Widget child) => CalestheticsFadeSlide(
      delay: Duration(milliseconds: 60 * order++),
      duration: const Duration(milliseconds: 380),
      offset: 16,
      child: child,
    );

    final sections = <Widget>[
      if (e.startingPosition != null)
        _Section(
          icon: Icons.accessibility_new_rounded,
          title: 'Starting position',
          child: _Body(e.startingPosition!),
        ),
      if (e.steps.isNotEmpty)
        _Section(
          icon: Icons.format_list_numbered_rounded,
          title: 'How to',
          child: _Steps(steps: e.steps),
        ),
      if (e.cues != null)
        _Section(
          icon: Icons.record_voice_over_rounded,
          title: 'Key cues',
          child: _Cues(text: e.cues!),
        ),
      if (e.breathing != null)
        _Section(
          icon: Icons.air_rounded,
          title: 'Breathing',
          child: _Body(e.breathing!),
        ),
      if (e.mistakes != null)
        _Section(
          icon: Icons.error_outline_rounded,
          title: 'Common mistakes',
          tint: c.accentText,
          child: _Body(e.mistakes!),
        ),
      if (e.safety != null)
        _Section(
          icon: Icons.health_and_safety_outlined,
          title: 'Safety',
          child: _Body(e.safety!),
        ),
    ];

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          // Soft rose wash behind the top of the page.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 360,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [c.softRose.withValues(alpha: 0.7), c.background],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                Row(
                  children: [
                    GlassButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    FavoriteHeart(number: e.number, size: 26),
                  ],
                ),
                const SizedBox(height: 14),
                _Hero(
                  exercise: e,
                  locked: locked,
                  hasVideo: hasVideo,
                  onPlay: play,
                ),
                const SizedBox(height: 18),
                enter(
                  Text(e.name, style: AppTypography.title(28, c.textPrimary)),
                ),
                const SizedBox(height: 6),
                enter(
                  Text(e.purpose, style: AppTypography.body(c.textSecondary)),
                ),
                const SizedBox(height: 14),
                enter(
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      InfoChip(
                        label: e.level.label,
                        icon: Icons.signal_cellular_alt_rounded,
                      ),
                      InfoChip(
                        label: e.equipment,
                        icon: Icons.fitness_center_rounded,
                      ),
                      InfoChip(
                        label: '${PlanBuilder.drillSeconds} s sets',
                        icon: Icons.timer_outlined,
                      ),
                    ],
                  ),
                ),
                for (final s in sections) enter(s),
                if (nb.easier != null || nb.harder != null)
                  enter(_Ladder(easier: nb.easier, harder: nb.harder))
                else if (e.easier != null || e.harder != null)
                  enter(
                    _Section(
                      icon: Icons.swap_vert_rounded,
                      title: 'Make it easier or harder',
                      child: _Body(
                        [
                          if (e.easier != null) 'Easier: ${e.easier}',
                          if (e.harder != null) 'Harder: ${e.harder}',
                        ].join('\n'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // The one way to start the video: a 30 s try-out in the player.
          if (hasVideo)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20 + MediaQuery.paddingOf(context).bottom,
              child: CalestheticsFadeSlide(
                delay: const Duration(milliseconds: 250),
                child: _TryButton(locked: locked, onTap: play),
              ),
            ),
        ],
      ),
    );
  }
}

/// The exercise's thumbnail in its own 4:3 card, with a pulsing play button.
class _Hero extends StatefulWidget {
  const _Hero({
    required this.exercise,
    required this.locked,
    required this.hasVideo,
    required this.onPlay,
  });

  final Exercise exercise;
  final bool locked;
  final bool hasVideo;
  final VoidCallback onPlay;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
    } else {
      if (!_enter.isAnimating && _enter.value == 0) _enter.forward();
      if (!_pulse.isAnimating) _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final e = widget.exercise;
    final canPlay = widget.hasVideo;
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_enter.value);
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
        );
      },
      child: GestureDetector(
        onTap: canPlay ? widget.onPlay : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: c.accent.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: AspectRatio(
              aspectRatio: 1200 / 896, // the thumbnails' own shape
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExercisePicture(exercise: e),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0),
                          Colors.black.withValues(alpha: 0.45),
                        ],
                        stops: const [0.55, 1],
                      ),
                    ),
                  ),
                  if (canPlay)
                    Center(
                      child: AnimatedBuilder(
                        key: const ValueKey('exercise-play'),
                        animation: _pulse,
                        builder: (context, _) => _PlayButton(
                          pulse: _pulse.value,
                          locked: widget.locked,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 14,
                    bottom: 12,
                    right: 14,
                    child: Row(
                      children: [
                        Icon(
                          canPlay
                              ? Icons.play_circle_outline_rounded
                              : Icons.videocam_off_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          canPlay
                              ? (widget.locked
                                    ? 'Premium video'
                                    : 'Tap to try it · ${PlanBuilder.drillSeconds} s')
                              : 'No video for this exercise',
                          style: AppTypography.body(
                            Colors.white,
                            fontSize: 13,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.pulse, required this.locked});
  final double pulse;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // A ring breathes out from the button.
          Container(
            width: 72 + 48 * pulse,
            height: 72 + 48 * pulse,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6 * (1 - pulse)),
                width: 2,
              ),
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.accent,
              boxShadow: [
                BoxShadow(
                  color: c.accent.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              locked ? Icons.lock_rounded : Icons.play_arrow_rounded,
              size: locked ? 30 : 40,
              color: c.onAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _TryButton extends StatelessWidget {
  const _TryButton({required this.locked, required this.onTap});
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SizedBox(
      height: 58,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          shape: const StadiumBorder(),
          elevation: 6,
          shadowColor: c.accent.withValues(alpha: 0.4),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              locked ? Icons.lock_rounded : Icons.play_arrow_rounded,
              color: c.onAccent,
            ),
            const SizedBox(width: 8),
            Text(
              locked
                  ? 'Unlock with Premium'
                  : 'Try it · ${PlanBuilder.drillSeconds} s',
              style: AppTypography.title(16, c.onAccent),
            ),
          ],
        ),
      ),
    );
  }
}

/// A titled white card with a small round icon.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    this.tint,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: c.textPrimary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c.surfaceSelected,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17, color: tint ?? c.accentText),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTypography.title(16, c.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTypography.body(context.appColors.textSecondary));
}

/// Numbered steps joined by a thin line, like a little timeline.
class _Steps extends StatelessWidget {
  const _Steps({required this.steps});
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 26,
                  child: Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.accent,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: AppTypography.title(12, c.onAccent),
                        ),
                      ),
                      if (i < steps.length - 1)
                        Expanded(child: Container(width: 2, color: c.softRose)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 3,
                      bottom: i < steps.length - 1 ? 14 : 0,
                    ),
                    child: Text(
                      steps[i],
                      style: AppTypography.body(c.textSecondary),
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

/// "Small steps. Arms locked." -> one pill per cue.
class _Cues extends StatelessWidget {
  const _Cues({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final cues = text
        .split(RegExp(r'(?<=[.!])\s+'))
        .map((s) => s.trim().replaceAll(RegExp(r'[.!]$'), ''))
        .where((s) => s.isNotEmpty)
        .toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final cue in cues)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: c.surfaceSelected,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              cue,
              style: AppTypography.body(
                c.textPrimary,
                fontSize: 13,
                weight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ),
      ],
    );
  }
}

/// The easier and harder rung of the same ladder, side by side.
class _Ladder extends StatelessWidget {
  const _Ladder({required this.easier, required this.harder});
  final Exercise? easier;
  final Exercise? harder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Expanded(
            child: easier == null
                ? const SizedBox.shrink()
                : _RungCard(label: 'Easier', exercise: easier!),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: harder == null
                ? const SizedBox.shrink()
                : _RungCard(label: 'Harder', exercise: harder!),
          ),
        ],
      ),
    );
  }
}

class _RungCard extends StatelessWidget {
  const _RungCard({required this.label, required this.exercise});
  final String label;
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: () => context.push('/exercise/${exercise.number}'),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1200 / 896,
              child: ExercisePicture(exercise: exercise, compact: true),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: AppTypography.kicker(c.accentText, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exercise.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title(14, c.textPrimary),
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
