import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/onboarding_step.dart';

/// Animated growth-curve chart ("Potential", "Projection" screens): the line
/// draws itself in, then each labeled point fades in with a stagger so the
/// story reads left-to-right instead of popping in all at once.
class CurveStepContent extends StatefulWidget {
  const CurveStepContent({super.key, required this.step});

  final CurveStep step;

  @override
  State<CurveStepContent> createState() => _CurveStepContentState();
}

class _CurveStepContentState extends State<CurveStepContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.staged,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.screenBottomCta),
      child: Column(
        children: [
          // Room above the plot for the last point's label.
          const SizedBox(height: 36),
          SizedBox(
            height: 250,
            child: LayoutBuilder(
              builder: (context, constraints) => AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Stack(
                    clipBehavior: Clip.none,
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: _CurvePainter(
                          colors: context.appColors,
                          progress: Curves.easeOut.transform(_controller.value),
                        ),
                      ),
                      for (var k = 0; k < step.points.length; k++)
                        _PointMarker(
                          point: step.points[k],
                          areaSize: constraints.biggest,
                          opacity: CurvedAnimation(
                            parent: _controller,
                            curve: Interval(
                              (0.25 + k * 0.3).clamp(0, 1),
                              1,
                              curve: Curves.easeOut,
                            ),
                          ).value,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final label in step.xAxisLabels)
                  Text(
                    label,
                    style: AppTypography.kicker(
                      context.appColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.xxxl,
              AppSpacing.lg,
              AppSpacing.xxxl,
              0,
            ),
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: context.appColors.divider, width: 2),
              ),
            ),
            child: Text(
              step.footer,
              style: AppTypography.body(context.appColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointMarker extends StatelessWidget {
  const _PointMarker({
    required this.point,
    required this.areaSize,
    required this.opacity,
  });

  final CurvePoint point;
  final Size areaSize;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    // Points near the right edge anchor by their right side so the label
    // never runs off screen; the dot stays exactly on the curve either way.
    final nearRight = point.xFraction > 0.7;
    final x = areaSize.width * point.xFraction;
    return Positioned(
      left: nearRight ? null : x - 8,
      right: nearRight ? areaSize.width - x - 8 : null,
      // Anchor the dot (the column's bottom) on the curve; the label sits above.
      bottom: areaSize.height * (1 - point.yFraction) - 8,
      child: Opacity(
        opacity: opacity.clamp(0, 1),
        child: Column(
          crossAxisAlignment: nearRight
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 22),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: point.emphasized
                    ? context.appColors.accent
                    : context.appColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                point.label,
                style: AppTypography.title(
                  14,
                  point.emphasized
                      ? context.appColors.onAccent
                      : context.appColors.textPrimary,
                  weight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: context.appColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: context.appColors.accent, width: 4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  _CurvePainter({required this.progress, required this.colors});

  final double progress;
  final AppColorsExtension colors;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.84)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.82,
        size.width * 0.28,
        size.height * 0.76,
        size.width * 0.41,
        size.height * 0.60,
      )
      ..cubicTo(
        size.width * 0.54,
        size.height * 0.44,
        size.width * 0.69,
        size.height * 0.24,
        size.width,
        size.height * 0.12,
      );

    final metric = path.computeMetrics().first;
    final extracted = metric.extractPath(0, metric.length * progress);

    final paint = Paint()
      ..color = colors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colors.softRose.withValues(alpha: 0.45),
          colors.softRose.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fillPaint);
    canvas.drawPath(extracted, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}
