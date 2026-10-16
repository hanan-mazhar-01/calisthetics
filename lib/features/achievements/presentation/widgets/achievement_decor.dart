import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';

/// Pink ribbon with notched ends: "Achievements".
class RibbonBanner extends StatelessWidget {
  const RibbonBanner({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return CustomPaint(
      painter: _RibbonPainter(c.accent, c.accent.withValues(alpha: 0.78)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 9),
        child: Text(
          text,
          style: AppTypography.title(22, c.onAccent, weight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  _RibbonPainter(this.a, this.b);
  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const notch = 14.0;
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w - notch, h / 2)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..lineTo(notch, h / 2)
      ..close();
    canvas.drawPath(
      p,
      Paint()
        ..shader = LinearGradient(colors: [b, a, b])
            .createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => old.a != a || old.b != b;
}

/// Two leafy branches curving round a medal.
class LaurelWreath extends StatelessWidget {
  const LaurelWreath({super.key, required this.size, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return CustomPaint(
      size: Size.square(size),
      painter: _LaurelPainter(color ?? c.accent.withValues(alpha: 0.28)),
    );
  }
}

class _LaurelPainter extends CustomPainter {
  _LaurelPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.5;
    final paint = Paint()..color = color;
    for (final side in [-1.0, 1.0]) {
      for (var i = 0; i < 9; i++) {
        final t = i / 8;
        // Branch runs from the bottom up the side, curving inwards.
        final angle = math.pi / 2 + side * (0.35 + t * 1.75);
        final p = Offset(
          c.dx + r * 0.88 * math.cos(angle) * (1 - 0.12 * t),
          c.dy + r * 0.88 * math.sin(angle) * (1 - 0.12 * t),
        );
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(angle + (side > 0 ? 0.35 : -0.35) + math.pi);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: size.width * (0.2 - t * 0.05),
            height: size.width * (0.085 - t * 0.02),
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_LaurelPainter old) => old.color != color;
}

/// Magenta-pink stage lights fanning down from the top corners.
class SpotlightBeams extends StatelessWidget {
  const SpotlightBeams({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BeamPainter(color), size: Size.infinite);
}

class _BeamPainter extends CustomPainter {
  _BeamPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 0.62);
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0)],
    ).createShader(rect);
    final paint = Paint()..shader = shader;
    Path beam(double x0, double x1, double y1) => Path()
      ..moveTo(x0 - 18, 0)
      ..lineTo(x0 + 18, 0)
      ..lineTo(x1 + size.width * 0.16, y1)
      ..lineTo(x1 - size.width * 0.16, y1)
      ..close();
    canvas.drawPath(
      beam(size.width * 0.06, size.width * 0.34, rect.height),
      paint,
    );
    canvas.drawPath(
      beam(size.width * 0.94, size.width * 0.66, rect.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BeamPainter old) => old.color != color;
}

/// Falling confetti. [t] runs 0→1 and loops; [still] draws nothing moving.
class ConfettiLayer extends StatelessWidget {
  const ConfettiLayer({super.key, required this.t, required this.palette});
  final double t;
  final List<Color> palette;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _ConfettiPainter(t, palette),
      size: Size.infinite,
    ),
  );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.palette);
  final double t;
  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    for (var i = 0; i < 46; i++) {
      final x = rnd.nextDouble() * size.width;
      final speed = 0.6 + rnd.nextDouble() * 0.9;
      final phase = rnd.nextDouble();
      final fall = ((t * speed + phase) % 1.0);
      final y = fall * (size.height * 0.95);
      final sway = math.sin((t * 2 + phase) * math.pi * 2) * 12;
      final w = 5 + rnd.nextDouble() * 6;
      final h = 3 + rnd.nextDouble() * 4;
      canvas.save();
      canvas.translate(x + sway, y);
      canvas.rotate((t * 4 + phase) * math.pi * 2);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        Paint()
          ..color = palette[i % palette.length].withValues(
            alpha: 1 - (fall > 0.85 ? (fall - 0.85) / 0.15 : 0),
          ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
