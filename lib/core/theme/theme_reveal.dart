import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui' show FrameTiming;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Switching light and dark as a diamond reveal: a picture of the old look
/// sits on top while the new theme is applied underneath, and a diamond that
/// grows from the finger opens a window onto the new look. The old picture
/// also fades out near the end, so the edge dissolves instead of snapping.
class ThemeReveal {
  ThemeReveal._();

  /// True while a reveal is running; the app turns its own colour fade off so
  /// the two do not fight.
  static final ValueNotifier<bool> running = ValueNotifier(false);

  static _ThemeRevealHostState? _host;

  /// Applies [apply] (which changes the theme) with the diamond reveal,
  /// starting at [origin] in global coordinates. Without a host, or when
  /// animations are off, it just applies.
  static Future<void> run(Offset origin, VoidCallback apply) async {
    final host = _host;
    if (host == null || !host.mounted || running.value) {
      apply();
      return;
    }
    await host._run(origin, apply);
  }
}

class ThemeRevealHost extends StatefulWidget {
  const ThemeRevealHost({super.key, required this.child});
  final Widget child;

  @override
  State<ThemeRevealHost> createState() => _ThemeRevealHostState();
}

class _ThemeRevealHostState extends State<ThemeRevealHost>
    with SingleTickerProviderStateMixin {
  static const duration = Duration(milliseconds: 1200);

  final _boundary = GlobalKey();
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: duration,
  );
  ui.Image? _snapshot;
  Offset _origin = Offset.zero;

  @override
  void initState() {
    super.initState();
    ThemeReveal._host = this;
  }

  @override
  void dispose() {
    if (ThemeReveal._host == this) ThemeReveal._host = null;
    _controller.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  Future<void> _run(Offset origin, VoidCallback apply) async {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final object = _boundary.currentContext?.findRenderObject();
    if (reduce || object is! RenderRepaintBoundary) {
      apply();
      return;
    }
    ThemeReveal.running.value = true;
    try {
      final image = await object.toImage(
        pixelRatio: View.of(context).devicePixelRatio,
      );
      // Reading the pixels back makes sure the picture is fully ready on the
      // GPU; otherwise its first frames can paint blank and let the new
      // theme show through for a moment.
      await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() {
        _snapshot?.dispose();
        _snapshot = image;
        _origin = origin;
      });
      // Wait until the old picture has really been drawn to the screen (the
      // raster thread reports finished frames), so the new theme can never
      // show through before it.
      await WidgetsBinding.instance.endOfFrame;
      await _framesRastered(2);
      // Start opening the diamond first and change the theme a few frames in:
      // by then the window is a real shape and the old picture is certainly on
      // screen, so the new look only ever shows inside the diamond.
      final running = _controller.forward(from: 0);
      while (_controller.value < 0.03) {
        await WidgetsBinding.instance.endOfFrame;
      }
      apply();
      await running;
    } finally {
      if (mounted) {
        setState(() {
          _snapshot?.dispose();
          _snapshot = null;
        });
      }
      ThemeReveal.running.value = false;
    }
  }

  /// Completes once the engine has finished drawing at least [count] more
  /// frames (or after a short timeout, so a quiet screen cannot stall it).
  Future<void> _framesRastered(int count) {
    final done = Completer<void>();
    var seen = 0;
    void onTimings(List<FrameTiming> timings) {
      seen += timings.length;
      if (seen >= count && !done.isCompleted) done.complete();
    }

    WidgetsBinding.instance.addTimingsCallback(onTimings);
    // Make sure frames keep coming while we wait.
    WidgetsBinding.instance.scheduleFrame();
    return done.future
        .timeout(const Duration(milliseconds: 600), onTimeout: () {})
        .whenComplete(
          () => WidgetsBinding.instance.removeTimingsCallback(onTimings),
        );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        RepaintBoundary(key: _boundary, child: widget.child),
        if (snapshot != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _RevealPainter(
                    image: snapshot,
                    origin: _origin,
                    t: _controller.value,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RevealPainter extends CustomPainter {
  _RevealPainter({required this.image, required this.origin, required this.t});

  final ui.Image image;
  final Offset origin;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // The diamond must grow far enough to cover the farthest corner.
    final far =
        [
              Offset.zero,
              Offset(size.width, 0),
              Offset(0, size.height),
              Offset(size.width, size.height),
            ]
            .map((c) => (c.dx - origin.dx).abs() + (c.dy - origin.dy).abs())
            .reduce((a, b) => a > b ? a : b);
    final eased = Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));
    final r = far * 1.04 * eased;

    final diamond = Path()
      ..moveTo(origin.dx, origin.dy - r)
      ..lineTo(origin.dx + r, origin.dy)
      ..lineTo(origin.dx, origin.dy + r)
      ..lineTo(origin.dx - r, origin.dy)
      ..close();
    final screen = Path()..addRect(Offset.zero & size);
    final old = Path.combine(PathOperation.difference, screen, diamond);

    // The old picture dims a little as the window opens, and dissolves over
    // the last stretch so nothing is left behind.
    final fadeOut = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);

    canvas.save();
    // A diamond of zero size is a degenerate path that clips everything away,
    // which would show the new theme for a moment before the reveal starts.
    // Until it has a real size the old picture is simply drawn whole.
    if (r > 1) canvas.clipPath(old);
    final paint = Paint()..color = Color.fromRGBO(255, 255, 255, fadeOut);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      paint,
    );
    canvas.restore();

    // A glowing edge rides the diamond's outline and fades as it grows.
    final glow = (1 - t).clamp(0.0, 1.0);
    if (r > 2 && glow > 0) {
      canvas.drawPath(
        diamond,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeJoin = StrokeJoin.miter
          ..color = Color.fromRGBO(255, 255, 255, 0.35 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
      canvas.drawPath(
        diamond,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.miter
          ..color = Color.fromRGBO(255, 255, 255, 0.55 * glow),
      );
    }
  }

  @override
  bool shouldRepaint(_RevealPainter old) =>
      old.t != t || old.image != image || old.origin != origin;
}
