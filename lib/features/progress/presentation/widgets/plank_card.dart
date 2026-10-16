import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../domain/progress_models.dart';
import 'progress_motion.dart';

class PlankCard extends StatelessWidget {
  const PlankCard({super.key, required this.trend, required this.delay});
  final PlankTrend trend;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final gain = trend.gain;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plank hold',
                      style: AppTypography.title(
                        16,
                        c.textPrimary,
                        weight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Personal record, by week',
                      style: AppTypography.body(
                        c.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${trend.best} s',
                    style: AppTypography.title(
                      22,
                      c.textPrimary,
                      weight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  if (gain > 0)
                    Text(
                      '+$gain s since day 1',
                      style: AppTypography.body(
                        c.success,
                        fontSize: 12,
                        weight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label:
                'Line chart of your best plank hold per week: ${[for (final p in trend.points) 'week ${p.weekIndex} ${p.seconds} seconds'].join(', ')}',
            excludeSemantics: true,
            child: RepaintBoundary(
              child: StaggerClock(
                delay: delay,
                duration: const Duration(milliseconds: 1300),
                curve: Curves.easeOutCubic,
                builder: (context, t) => CustomPaint(
                  size: const Size(double.infinity, 120),
                  painter: _LinePainter(
                    points: trend.points,
                    t: t,
                    line: c.accent,
                    dotFill: c.surface,
                    grid: c.divider,
                    label: c.textMuted,
                  ),
                ),
              ),
            ),
          ),
          if (trend.points.length == 1) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Test again in a few weeks to see your trend.',
              style: AppTypography.body(c.textSecondary, fontSize: 12.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.points,
    required this.t,
    required this.line,
    required this.dotFill,
    required this.grid,
    required this.label,
  });

  final List<PlankPoint> points;
  final double t;
  final Color line;
  final Color dotFill;
  final Color grid;
  final Color label;

  static const _labelH = 22.0;
  static const _padX = 28.0;
  static const _padTop = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final n = points.length;
    final base = size.height - _labelH;
    canvas.drawLine(
      Offset(0, base),
      Offset(size.width, base),
      Paint()
        ..color = grid
        ..strokeWidth = 1,
    );
    final lo = points.map((p) => p.seconds).reduce(math.min);
    final hi = points.map((p) => p.seconds).reduce(math.max);
    final top = _padTop;
    final bottom = base - 12;
    final xs = <double>[];
    final ys = <double>[];
    for (var i = 0; i < n; i++) {
      xs.add(
        n == 1
            ? size.width / 2
            : _padX + (size.width - 2 * _padX) * i / (n - 1),
      );
      ys.add(
        hi == lo
            ? (top + bottom) / 2
            : bottom - (bottom - top) * (points[i].seconds - lo) / (hi - lo),
      );
    }

    // Smooth path: cubic segments with horizontal tangents.
    final path = Path()..moveTo(xs[0], ys[0]);
    for (var i = 1; i < n; i++) {
      final mx = (xs[i - 1] + xs[i]) / 2;
      path.cubicTo(mx, ys[i - 1], mx, ys[i], xs[i], ys[i]);
    }
    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (n > 1) {
      for (final PathMetric m in path.computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * t), stroke);
      }
    }

    for (var i = 0; i < n; i++) {
      // A dot pops as the line reaches it.
      final reach = n == 1 ? 0.0 : 0.85 * i / (n - 1);
      final p = Curves.easeOutBack.transform(
        ((t - reach) / 0.15).clamp(0.0, 1.0),
      );
      if (p <= 0) continue;
      final isLast = i == n - 1;
      final r = 4.5 * p;
      canvas.drawCircle(
        Offset(xs[i], ys[i]),
        r,
        Paint()..color = isLast ? line : dotFill,
      );
      canvas.drawCircle(
        Offset(xs[i], ys[i]),
        r,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: 'Wk ${points[i].weekIndex}',
          style: AppTypography.body(label, fontSize: 11.5),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      tp.paint(canvas, Offset(xs[i] - tp.width / 2, base + 6));
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.t != t || old.points != points || old.line != line;
}
