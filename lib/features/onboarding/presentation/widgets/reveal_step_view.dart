import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/onboarding_step.dart';

const _statIcons = [
  Icons.calendar_month_rounded,
  Icons.repeat_rounded,
  Icons.timer_outlined,
];

/// Light reveal of the generated plan's headline stats: a glowing centre
/// card with the stats orbiting it. Pills pop in one by one, numbers count up,
/// then everything drifts gently (rings turn, pills float, sparkles twinkle).
class RevealStepView extends StatefulWidget {
  const RevealStepView({super.key, required this.step, required this.onNext});

  final RevealStep step;
  final VoidCallback onNext;

  @override
  State<RevealStepView> createState() => _RevealStepViewState();
}

class _RevealStepViewState extends State<RevealStepView>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..forward();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honour "remove animations": show the finished picture, no drifting.
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Stack(
      children: [
        Positioned.fill(child: _SoftBackground(colors: c)),
        Column(
          children: [
            const SizedBox(height: AppSpacing.xxxl),
            _fade(0, 0.09, child: _KickerPill(colors: c)),
            const SizedBox(height: AppSpacing.xl),
            _fade(0.05, 0.16, child: _Headline(colors: c)),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final side = math.min(box.maxWidth, box.maxHeight);
                  return Center(
                    child: RepaintBoundary(
                      child: SizedBox(
                        width: box.maxWidth,
                        height: side,
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_intro, _loop]),
                          builder: (context, _) => _Orbit(
                            width: box.maxWidth,
                            height: side,
                            intro: _intro.value,
                            loop: _loop.value,
                            stats: widget.step.stats,
                            colors: c,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _fade(
              0.9,
              1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxxl,
                  0,
                  AppSpacing.xxxl,
                  AppSpacing.xxl,
                ),
                child: PrimaryButton(
                  label: widget.step.ctaLabel,
                  onPressed: widget.onNext,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Fade + small rise during the [from]–[to] slice of the intro.
  Widget _fade(double from, double to, {required Widget child}) {
    return AnimatedBuilder(
      animation: _intro,
      builder: (context, child) {
        final t = Curves.easeOut.transform(
          Interval(from, to).transform(_intro.value),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 12),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _SoftBackground extends StatelessWidget {
  const _SoftBackground({required this.colors});
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        gradient: RadialGradient(
          center: const Alignment(-1.0, -0.15),
          radius: 1.1,
          colors: [colors.softRose.withValues(alpha: 0.75), colors.background],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(1.0, 0.3),
            radius: 0.9,
            colors: [
              colors.softRose.withValues(alpha: 0.35),
              colors.background.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _KickerPill extends StatelessWidget {
  const _KickerPill({required this.colors});
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fitness_center_rounded, size: 17, color: colors.accent),
          const SizedBox(width: 9),
          Text(
            'YOUR PLAN IS READY',
            style: AppTypography.kicker(
              colors.accentText,
              fontSize: 12.5,
              letterSpacingEm: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.colors});
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    final base = AppTypography.display(
      fontSize: 36,
      color: colors.textPrimary,
      stretchPercent: 82,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'Everything is '),
          TextSpan(
            text: 'set',
            style: base.copyWith(color: colors.accentText),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Positions of the three pills on the orbit, as angles in degrees
/// (0 = right, 90 = down), and the phase offset of each one's float.
const _pillAngles = [-90.0, 125.0, 55.0];
const _pillPhases = [0.0, 2.1, 4.2];

class _Orbit extends StatelessWidget {
  const _Orbit({
    required this.width,
    required this.height,
    required this.intro,
    required this.loop,
    required this.stats,
    required this.colors,
  });

  final double width;
  final double height;
  final double intro;
  final double loop;
  final List<PlanStat> stats;
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    final cx = width / 2;
    final cy = height / 2;
    // A wider ring and a smaller centre keep the pills clear of the circle.
    final radius = math.min(width * 0.34, height * 0.37);
    final centerSize = radius * 0.92;
    final centerIn = Curves.elasticOut.transform(
      Interval(0.02, 0.2).transform(intro).clamp(0.0, 1.0),
    );
    final ringIn = Curves.easeOut.transform(
      Interval(0.05, 0.34).transform(intro),
    );
    final pulse = 1 + 0.025 * math.sin(loop * 2 * math.pi * 3);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _OrbitPainter(
              colors: colors,
              radius: radius,
              turn: loop * 2 * math.pi,
              reveal: ringIn,
              centerSize: centerSize,
            ),
          ),
        ),
        for (var i = 0; i < _sparkles.length; i++)
          _sparkle(i, cx, cy, width, height),
        Positioned(
          left: cx - centerSize / 2,
          top: cy - centerSize / 2,
          width: centerSize,
          height: centerSize,
          child: Transform.scale(
            scale: centerIn * pulse,
            child: _CenterCard(size: centerSize, colors: colors),
          ),
        ),
        for (var i = 0; i < stats.length && i < _pillAngles.length; i++)
          _pill(i, cx, cy, radius),
      ],
    );
  }

  /// Each pill is introduced on its own: it rides along the ring from a bit
  /// behind its place, grows in, settles with a small ripple, and its number
  /// counts up. The next one only starts when the last has landed.
  static const _sweepDegrees = 115.0;

  Widget _pill(int i, double cx, double cy, double radius) {
    final start = 0.3 + i * 0.2;
    final local = Interval(
      start,
      math.min(start + 0.22, 1),
    ).transform(intro).clamp(0.0, 1.0);
    final travel = Curves.easeOutCubic.transform(local);
    final grow = Curves.easeOutBack.transform(
      Interval(0, 0.55).transform(local).clamp(0.0, 1.0),
    );
    final opacity = Interval(0, 0.25).transform(local).clamp(0.0, 1.0);
    final target = _pillAngles[i];
    final angle = (target - _sweepDegrees * (1 - travel)) * math.pi / 180;
    final bob = math.sin(loop * 2 * math.pi * 2 + _pillPhases[i]) * 4 * local;
    final px = cx + math.cos(angle) * radius;
    final py = cy + math.sin(angle) * radius + bob;
    // A ripple where it lands.
    final ripple = Interval(0.7, 1).transform(local).clamp(0.0, 1.0);
    return Positioned(
      left: px,
      top: py,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (ripple > 0 && ripple < 1)
              Opacity(
                opacity: (1 - ripple) * 0.5,
                child: Container(
                  width: 70 + 120 * ripple,
                  height: 44 + 70 * ripple,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.accent, width: 1.6),
                  ),
                ),
              ),
            Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: 0.55 + 0.45 * grow,
                child: _StatPill(
                  stat: stats[i],
                  icon: _statIcons[i % _statIcons.length],
                  countT: local,
                  colors: colors,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sparkle(int i, double cx, double cy, double w, double h) {
    final s = _sparkles[i];
    final twinkle =
        0.45 + 0.55 * (0.5 + 0.5 * math.sin(loop * 2 * math.pi * 3 + s.phase));
    final appear = Interval(0.7, 1).transform(intro);
    return Positioned(
      left: w * s.x - s.size / 2,
      top: h * s.y - s.size / 2,
      child: Opacity(
        opacity: (twinkle * appear).clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: s.tilt,
          child: Icon(
            s.icon,
            size: s.size,
            color: colors.accent.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

/// Small training icons drifting around the ring (instead of generic
/// sparkles): a dumbbell, a heart and a bolt.
class _Sparkle {
  const _Sparkle(this.x, this.y, this.size, this.phase, this.icon, this.tilt);
  final double x;
  final double y;
  final double size;
  final double phase;
  final IconData icon;
  final double tilt;
}

const _sparkles = [
  _Sparkle(0.88, 0.1, 22, 0, Icons.fitness_center_rounded, 0.5),
  _Sparkle(0.08, 0.9, 18, 1.7, Icons.favorite_rounded, -0.2),
  _Sparkle(0.93, 0.55, 17, 3.1, Icons.bolt_rounded, 0.15),
];

class _CenterCard extends StatelessWidget {
  const _CenterCard({required this.size, required this.colors});
  final double size;
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.accent.withValues(alpha: 0.85), colors.accentPressed],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.35),
            blurRadius: 40,
            spreadRadius: 6,
          ),
          BoxShadow(
            color: colors.surface.withValues(alpha: 0.9),
            blurRadius: 0,
            spreadRadius: size * 0.09,
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(size * 0.06),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.onAccent.withValues(alpha: 0.35)),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              color: colors.onAccent,
              size: size * 0.26,
            ),
            SizedBox(height: size * 0.04),
            Text(
              'Your plan',
              style: AppTypography.title(
                size * 0.15,
                colors.onAccent,
                weight: FontWeight.w800,
              ),
            ),
            SizedBox(height: size * 0.02),
            Text(
              'READY',
              style: AppTypography.kicker(
                colors.onAccent.withValues(alpha: 0.9),
                fontSize: size * 0.085,
                letterSpacingEm: 0.12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.stat,
    required this.icon,
    required this.countT,
    required this.colors,
  });

  final PlanStat stat;
  final IconData icon;
  final double countT;
  final AppColorsExtension colors;

  /// Counts every number in "16–21" up from 0 while the intro plays.
  String _counted() {
    final t = Curves.easeOut.transform(Interval(0.25, 0.95).transform(countT));
    return stat.value.replaceAllMapped(
      RegExp(r'\d+'),
      (m) => (int.parse(m[0]!) * t).round().toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.surfaceSelected,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: colors.accentText),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _counted(),
                style: AppTypography.title(
                  17,
                  colors.textPrimary,
                  weight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              Text(
                stat.label,
                style: AppTypography.body(
                  colors.textSecondary,
                  fontSize: 11.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The dashed ring, two turning arcs with end dots, and a soft halo.
class _OrbitPainter extends CustomPainter {
  _OrbitPainter({
    required this.colors,
    required this.radius,
    required this.turn,
    required this.reveal,
    required this.centerSize,
  });

  final AppColorsExtension colors;
  final double radius;
  final double turn;
  final double reveal;
  final double centerSize;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);

    // Halo behind the centre card.
    canvas.drawCircle(
      c,
      centerSize * 0.95,
      Paint()
        ..shader = RadialGradient(
          colors: [
            colors.accent.withValues(alpha: 0.16 * reveal),
            colors.accent.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: centerSize * 0.95)),
    );

    // Dashed ring.
    final dash = Paint()
      ..color = colors.accent.withValues(alpha: 0.28 * reveal)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    const dashCount = 90;
    for (var i = 0; i < dashCount; i++) {
      final a = i / dashCount * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: radius),
        a,
        math.pi * 2 / dashCount * 0.45,
        false,
        dash,
      );
    }

    // Two solid arcs that slowly turn, each ending in a dot.
    final arc = Paint()
      ..color = colors.accent.withValues(alpha: 0.85 * reveal)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.6;
    final rect = Rect.fromCircle(center: c, radius: radius);
    for (final (start, sweep) in [
      (0.15 * math.pi, 0.55 * math.pi),
      (1.1 * math.pi, 0.5 * math.pi),
    ]) {
      final from = start + turn;
      canvas.drawArc(rect, from, sweep * reveal, false, arc);
      final end = from + sweep * reveal;
      canvas.drawCircle(
        c + Offset(math.cos(end), math.sin(end)) * radius,
        5.5,
        Paint()..color = colors.accent.withValues(alpha: reveal),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.turn != turn ||
      old.reveal != reveal ||
      old.radius != radius ||
      old.colors != colors ||
      old.centerSize != centerSize;
}
