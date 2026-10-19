import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The four tabs of the bottom bar.
enum NavIconKind { plan, discover, progress, profile }

/// How long one tap animation runs.
const navIconDuration = Duration(milliseconds: 800);

/// A bottom-bar icon drawn by hand on a 24 x 24 grid: a clean outline, plus a
/// soft second tone and a slightly heavier line while its tab is active.
///
/// [animation] runs 0 to 1 when the tab is tapped and gives each icon its own
/// little move: the plan's tick draws itself and its rings wiggle, the
/// compass needle swings to north, the progress line draws up to its arrow,
/// the profile's head drops in while the shoulders rise. Null (or 1) is the
/// icon at rest.
class NavIcon extends StatelessWidget {
  const NavIcon({
    super.key,
    required this.kind,
    required this.color,
    required this.tone,
    required this.activeness,
    this.animation,
    this.size = 22,
  });

  final NavIconKind kind;

  /// The line colour.
  final Color color;

  /// The soft fill that fades in with [activeness].
  final Color tone;

  /// 0 for an idle tab, 1 for the active one (in between while it glides).
  final double activeness;
  final Animation<double>? animation;
  final double size;

  @override
  Widget build(BuildContext context) {
    final a = animation;
    Widget paint(double t) => CustomPaint(
      size: Size.square(size),
      painter: NavIconPainter(
        kind: kind,
        color: color,
        tone: tone,
        activeness: activeness,
        t: t,
      ),
    );
    if (a == null) return paint(1);
    return AnimatedBuilder(animation: a, builder: (_, _) => paint(a.value));
  }
}

class NavIconPainter extends CustomPainter {
  const NavIconPainter({
    required this.kind,
    required this.color,
    required this.tone,
    required this.activeness,
    required this.t,
  });

  final NavIconKind kind;
  final Color color;
  final Color tone;
  final double activeness;

  /// The tap animation: 0 at the start, 1 at rest.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24);

    // Every tap first pops the whole icon.
    final pop = _keys(_win(t, 0, .625), const [0, .55, 1], const [.72, 1.2, 1]);
    final tilt = _keys(_win(t, 0, .625), const [0, .55, 1], const [-8, 3, 0]);
    canvas.translate(12, 12);
    canvas.rotate(tilt * math.pi / 180);
    canvas.scale(pop);
    canvas.translate(-12, -12);

    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 + 0.2 * activeness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = tone.withValues(alpha: tone.a * activeness)
      ..style = PaintingStyle.fill;

    switch (kind) {
      case NavIconKind.plan:
        _plan(canvas, line, fill);
      case NavIconKind.discover:
        _discover(canvas, line, fill);
      case NavIconKind.progress:
        _progress(canvas, line, fill);
      case NavIconKind.profile:
        _profile(canvas, line, fill);
    }
    canvas.restore();
  }

  // Plan: a calendar. The rings wiggle and the tick draws itself.
  void _plan(Canvas canvas, Paint line, Paint fill) {
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3.5, 5, 17, 15.5),
      const Radius.circular(4.5),
    );
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, line);

    final wiggle =
        _keys(
          _win(t, 0, .75),
          const [0, .25, .55, .8, 1],
          const [0, -16, 12, -5, 0],
        ) *
        math.pi /
        180;
    for (final x in const [8.0, 16.0]) {
      canvas.save();
      canvas.translate(x, 3);
      canvas.rotate(wiggle);
      canvas.drawLine(Offset.zero, const Offset(0, 3.6), line);
      canvas.restore();
    }
    canvas.drawLine(const Offset(3.8, 10.2), const Offset(20.2, 10.2), line);

    final tick = Path()
      ..moveTo(8.6, 15.3)
      ..lineTo(10.9, 17.6)
      ..lineTo(15.5, 12.8);
    _drawPartial(canvas, tick, line, _seg(t, .1, .7));
  }

  // Discover: a compass. The needle swings round to north.
  void _discover(Canvas canvas, Paint line, Paint fill) {
    const c = Offset(12, 12);
    canvas.drawCircle(c, 9, fill);
    canvas.drawCircle(c, 9, line);

    final swing =
        _keys(_win(t, 0, .94), const [0, .55, .78, 1], const [-90, 32, -9, 0]) *
        math.pi /
        180;
    canvas.save();
    canvas.translate(12, 12);
    canvas.rotate(swing);
    canvas.translate(-12, -12);
    final needle = Path()
      ..moveTo(15.9, 8.1)
      ..lineTo(13.7, 13.7)
      ..lineTo(8.1, 15.9)
      ..lineTo(10.3, 10.3)
      ..close();
    canvas.drawPath(needle, fill);
    canvas.drawPath(needle, line);
    canvas.restore();
    canvas.drawCircle(
      c,
      1.15,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  // Progress: a chart with a rising trend line. The line draws itself up
  // to the arrow, which pops at the end.
  void _progress(Canvas canvas, Paint line, Paint fill) {
    final axes = Path()
      ..moveTo(4, 4.5)
      ..lineTo(4, 17.5)
      ..arcToPoint(
        const Offset(6.5, 20),
        radius: const Radius.circular(2.5),
        clockwise: false,
      )
      ..lineTo(20, 20);
    canvas.drawPath(axes, line);

    final draw = _seg(t, .08, .75);
    final area = Path()
      ..moveTo(8, 15.5)
      ..lineTo(11.5, 11.5)
      ..lineTo(14.5, 14)
      ..lineTo(19.5, 8)
      ..lineTo(19.5, 17.5)
      ..lineTo(8, 17.5)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..color = fill.color.withValues(alpha: fill.color.a * draw)
        ..style = PaintingStyle.fill,
    );

    final trend = Path()
      ..moveTo(8, 15.5)
      ..lineTo(11.5, 11.5)
      ..lineTo(14.5, 14)
      ..lineTo(19.5, 8);
    _drawPartial(canvas, trend, line, draw);

    // The arrow head, popping about its tip.
    final pop = _keys(_win(t, .6, 1), const [0, .6, 1], const [0, 1.45, 1]);
    if (pop > 0.001) {
      canvas.save();
      canvas.translate(19.5, 8);
      canvas.scale(pop);
      canvas.translate(-19.5, -8);
      final head = Path()
        ..moveTo(15.8, 8)
        ..lineTo(19.5, 8)
        ..lineTo(19.5, 11.7);
      canvas.drawPath(head, line);
      canvas.restore();
    }
  }

  // Profile: a person. The head drops in and the shoulders rise.
  void _profile(Canvas canvas, Paint line, Paint fill) {
    final drop = _win(t, 0, .625);
    final dy = _keys(drop, const [0, .6, 1], const [-6, 1, 0]);
    final fade = _keys(drop, const [0, .6, 1], const [0, 1, 1]);

    final shoulders = Path()
      ..moveTo(4.6, 20.3)
      ..cubicTo(4.6, 16.4, 7.8, 14.1, 12, 14.1)
      ..cubicTo(16.2, 14.1, 19.4, 16.4, 19.4, 20.3);
    final rise = _keys(
      _win(t, .125, .75),
      const [0, .6, 1],
      const [.5, 1.1, 1],
    );
    canvas.save();
    canvas.translate(0, 20.3);
    canvas.scale(1, rise);
    canvas.translate(0, -20.3);
    canvas.drawPath(Path.from(shoulders)..close(), fill);
    canvas.drawPath(shoulders, line);
    canvas.restore();

    canvas.save();
    canvas.translate(0, dy);
    final fadedLine = Paint()
      ..color = color.withValues(alpha: color.a * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = line.strokeWidth
      ..strokeCap = StrokeCap.round;
    final fadedFill = Paint()
      ..color = fill.color.withValues(alpha: fill.color.a * fade)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(12, 8.3), 3.9, fadedFill);
    canvas.drawCircle(const Offset(12, 8.3), 3.9, fadedLine);
    canvas.restore();
  }

  @override
  bool shouldRepaint(NavIconPainter old) =>
      old.kind != kind ||
      old.color != color ||
      old.tone != tone ||
      old.activeness != activeness ||
      old.t != t;
}

/// Draws the first [fraction] of [path] (nothing at 0, all of it at 1).
void _drawPartial(Canvas canvas, Path path, Paint paint, double fraction) {
  if (fraction <= 0.001) return;
  if (fraction >= 0.999) {
    canvas.drawPath(path, paint);
    return;
  }
  for (final m in path.computeMetrics()) {
    canvas.drawPath(m.extractPath(0, m.length * fraction), paint);
  }
}

/// [t] rescaled so [from] to [to] becomes 0 to 1 (clamped).
double _win(double t, double from, double to) =>
    ((t - from) / (to - from)).clamp(0.0, 1.0);

/// [t] from [from] to [to] eased out, 0 to 1.
double _seg(double t, double from, double to) =>
    Curves.easeOutCubic.transform(_win(t, from, to));

/// Piecewise values: [values] at the times [at] (0 to 1), eased between.
double _keys(double u, List<double> at, List<double> values) {
  for (var i = 1; i < at.length; i++) {
    if (u <= at[i]) {
      final k = Curves.easeInOut.transform(
        ((u - at[i - 1]) / (at[i] - at[i - 1])).clamp(0.0, 1.0),
      );
      return values[i - 1] + (values[i] - values[i - 1]) * k;
    }
  }
  return values.last;
}
