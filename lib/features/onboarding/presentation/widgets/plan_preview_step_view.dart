import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/media_placeholder.dart';
import '../../../exercises/domain/exercise_lookup.dart';
import '../../../exercises/presentation/widgets/exercise_picture.dart';
import '../../domain/onboarding_step.dart';
import 'intro_motion.dart';

const _phaseIcons = [
  Icons.eco_rounded,
  Icons.local_fire_department_rounded,
  Icons.fitness_center_rounded,
  Icons.spa_rounded,
];

/// "Four phases" preview: a numbered timeline, one card per phase with its
/// session name and a row of exercise thumbnails labelled with real targets.
class PlanPreviewStepView extends StatefulWidget {
  const PlanPreviewStepView({
    super.key,
    required this.step,
    required this.onNext,
  });

  final PlanPreviewStep step;
  final VoidCallback onNext;

  @override
  State<PlanPreviewStepView> createState() => _PlanPreviewStepViewState();
}

class _PlanPreviewStepViewState extends State<PlanPreviewStepView>
    with SingleTickerProviderStateMixin {
  /// Each phase gets this slice of the clock to itself, one after another.
  static const _first = 0.1;
  static const _each = 0.2;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PlanPreviewStep get step => widget.step;
  VoidCallback get onNext => widget.onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            child: Column(
              children: [
                IntroReveal(
                  animation: _controller,
                  from: 0,
                  to: 0.1,
                  slide: const Offset(0, 10),
                  child: const _LinedTitle('FOUR PHASES'),
                ),
                const SizedBox(height: AppSpacing.xxl),
                for (var i = 0; i < step.phases.length; i++)
                  _TimelineEntry(
                    phase: step.phases[i],
                    index: i,
                    isLast: i == step.phases.length - 1,
                    animation: _controller,
                    start: _first + i * _each,
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: IntroReveal(
            animation: _controller,
            from: 0.93,
            to: 1,
            child: Semantics(
              button: true,
              label: step.ctaLabel,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onNext,
                child: Container(
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [
                        c.accent,
                        Color.alphaBlend(
                          c.softRose.withValues(alpha: 0.55),
                          c.accent,
                        ),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.accent.withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    step.ctaLabel,
                    style: AppTypography.title(
                      18,
                      c.onAccent,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Letter-spaced pink label flanked by fading lines.
class _LinedTitle extends StatelessWidget {
  const _LinedTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    Widget line(bool left) => Expanded(
      child: Container(
        height: 1.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: left ? Alignment.centerLeft : Alignment.centerRight,
            end: left ? Alignment.centerRight : Alignment.centerLeft,
            colors: [
              c.accent.withValues(alpha: 0),
              c.accent.withValues(alpha: 0.45),
            ],
          ),
        ),
      ),
    );
    return Row(
      children: [
        line(true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            text,
            style: AppTypography.kicker(
              c.accentText,
              fontSize: 18,
              letterSpacingEm: 0.22,
            ),
          ),
        ),
        line(false),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.phase,
    required this.index,
    required this.isLast,
    required this.animation,
    required this.start,
  });

  final ProgramPhase phase;
  final int index;
  final bool isLast;
  final Animation<double> animation;
  final double start;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 58,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) => CustomPaint(
                painter: _DashPainter(
                  color: c.accent.withValues(alpha: 0.5),
                  drawLine: !isLast,
                  // The dashed line runs down to the next phase after this
                  // one has appeared.
                  progress: slice(
                    animation.value,
                    start + 0.05,
                    start + 0.22,
                    Curves.easeInOut,
                  ),
                ),
                child: child,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: IntroReveal(
                  animation: animation,
                  from: start,
                  to: start + 0.06,
                  slide: Offset.zero,
                  pop: true,
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.alphaBlend(
                            c.softRose.withValues(alpha: 0.6),
                            c.accent,
                          ),
                          c.accent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: c.accent.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      phase.number,
                      style: AppTypography.title(
                        20,
                        c.onAccent,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xl),
              child: IntroReveal(
                animation: animation,
                from: start + 0.02,
                to: start + 0.1,
                slide: const Offset(44, 0),
                child: _PhaseCard(
                  phase: phase,
                  icon: _phaseIcons[index % _phaseIcons.length],
                  index: index,
                  animation: animation,
                  start: start + 0.08,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter({
    required this.color,
    required this.drawLine,
    this.progress = 1,
  });
  final Color color;
  final bool drawLine;

  /// How much of the line is drawn so far (0 to 1).
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (!drawLine) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2;
    var y = 66.0;
    final end = 66.0 + (size.height - 66.0) * progress;
    while (y < end) {
      canvas.drawLine(Offset(x, y), Offset(x, (y + 6).clamp(0, end)), paint);
      y += 12;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) =>
      old.color != color ||
      old.drawLine != drawLine ||
      old.progress != progress;
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({
    required this.phase,
    required this.icon,
    required this.index,
    required this.animation,
    required this.start,
  });

  final ProgramPhase phase;
  final IconData icon;
  final int index;
  final Animation<double> animation;
  final double start;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final title = phase.sessionName.isEmpty ? phase.label : phase.sessionName;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: c.accent.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEEK ${index + 1} · ${phase.label.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.kicker(
                        c.textMuted,
                        fontSize: 12.5,
                        letterSpacingEm: 0.12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title(
                        21,
                        c.textPrimary,
                        weight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 34, color: c.accent),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < phase.exercises.length; i++) ...[
                if (i != 0) const SizedBox(width: 8),
                Expanded(
                  // The exercises appear one after another inside the card.
                  child: IntroReveal(
                    animation: animation,
                    from: start + i * 0.022,
                    to: start + i * 0.022 + 0.07,
                    slide: const Offset(0, 14),
                    pop: true,
                    child: _Thumb(
                      number: i < phase.exerciseNumbers.length
                          ? phase.exerciseNumbers[i]
                          : null,
                      name: phase.exercises[i],
                      target: i < phase.targets.length ? phase.targets[i] : '',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.number,
    required this.name,
    required this.target,
  });

  final int? number;
  final String name;
  final String target;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      label: '$name, $target',
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (number != null)
                ExercisePicture(
                  exercise: exerciseByNumber(number!),
                  compact: true,
                )
              else
                MediaPlaceholder(brief: name, compact: true),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 30,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        c.cover.withValues(alpha: 0),
                        c.cover.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 5,
                child: Text(
                  target,
                  textAlign: TextAlign.center,
                  style: AppTypography.title(
                    14,
                    Colors.white,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
