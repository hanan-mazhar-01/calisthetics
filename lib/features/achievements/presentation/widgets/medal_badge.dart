import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';

/// A hexagon medal: silver rim, big number, small unit caption and a star in
/// the app's accent colour. Locked medals are a faint outline.
class MedalBadge extends StatelessWidget {
  const MedalBadge({
    super.key,
    required this.number,
    required this.unit,
    required this.earned,
    this.size = 88,
  });

  final String number;
  final String unit;
  final bool earned;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MedalPainter(
          number: number,
          unit: unit,
          earned: earned,
          accent: c.accent,
          accentDark: c.accentPressed,
          outline: c.textMuted,
          faint: c.divider,
        ),
      ),
    );
  }
}

double _numberScale(String n) => switch (n.length) {
  1 => 0.44,
  2 => 0.36,
  _ => 0.27,
};

class _MedalPainter extends CustomPainter {
  _MedalPainter({
    required this.number,
    required this.unit,
    required this.earned,
    required this.accent,
    required this.accentDark,
    required this.outline,
    required this.faint,
  });

  final String number;
  final String unit;
  final bool earned;
  final Color accent;
  final Color accentDark;
  final Color outline;
  final Color faint;

  Path _hex(Offset c, double r) {
    final p = Path();
    for (var i = 0; i < 6; i++) {
      final a = math.pi / 3 * i;
      final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  Path _star(Offset c, double r) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + math.pi / 5 * i;
      final rr = i.isEven ? r : r * 0.48;
      final pt = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);
    final r = s * 0.46;
    final rim = s * 0.055;
    final hex = _hex(c, r);

    if (earned) {
      // Soft drop shadow, then a silver body with a lighter top edge.
      canvas.drawPath(
        hex.shift(Offset(0, s * 0.03)),
        Paint()
          ..color = const Color(0x26000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.03),
      );
      canvas.drawPath(
        hex,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFD5D8DD)],
          ).createShader(Offset.zero & size),
      );
      canvas.drawPath(
        hex,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rim
          ..strokeJoin = StrokeJoin.round
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4F5F7), Color(0xFF9CA2AA), Color(0xFFE6E8EB)],
          ).createShader(Offset.zero & size),
      );
    } else {
      canvas.drawPath(hex, Paint()..color = const Color(0x14FFFFFF));
      canvas.drawPath(
        hex,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rim * 0.6
          ..strokeJoin = StrokeJoin.round
          ..color = faint,
      );
    }

    // Number, large and a little left of centre; unit caption above its right.
    final numberColor = earned ? const Color(0xFF9EA4AC) : faint;
    final tp = TextPainter(
      text: TextSpan(
        text: number,
        style: TextStyle(
          fontSize: s * _numberScale(number),
          fontWeight: FontWeight.w800,
          height: 1,
          color: numberColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final numberOffset = Offset(c.dx - r * 0.68, c.dy - r * 0.62);
    if (earned) {
      tp.paint(canvas, numberOffset + Offset(s * 0.008, s * 0.012));
    }
    final emboss = TextPainter(
      text: TextSpan(
        text: number,
        style: TextStyle(
          fontSize: s * _numberScale(number),
          fontWeight: FontWeight.w800,
          height: 1,
          color: earned ? const Color(0xFFB9BEC5) : faint,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    emboss.paint(canvas, numberOffset);

    final cap = TextPainter(
      text: TextSpan(
        text: unit,
        style: TextStyle(
          fontSize: s * 0.075,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: earned ? const Color(0xFFA3A8AF) : faint,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    cap.paint(canvas, Offset(c.dx - cap.width / 2, c.dy - r * 0.8));

    // The star, bottom-right, overlapping the number.
    final starC = Offset(c.dx + r * 0.3, c.dy + r * 0.26);
    final star = _star(starC, r * 0.46);
    if (earned) {
      canvas.drawPath(
        star.shift(Offset(0, s * 0.015)),
        Paint()
          ..color = const Color(0x33000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.02),
      );
      canvas.drawPath(
        star,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [accent, accentDark],
          ).createShader(star.getBounds()),
      );
      canvas.drawPath(
        star,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.03
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFFE9EBEE),
      );
      // A glossy highlight on the upper edge.
      canvas.drawPath(
        _star(starC.translate(0, -r * 0.05), r * 0.34),
        Paint()..color = const Color(0x33FFFFFF),
      );
    } else {
      canvas.drawPath(
        star,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rim * 0.55
          ..strokeJoin = StrokeJoin.round
          ..color = faint,
      );
    }
  }

  @override
  bool shouldRepaint(_MedalPainter old) =>
      old.number != number ||
      old.unit != unit ||
      old.earned != earned ||
      old.accent != accent ||
      old.faint != faint;
}
