import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui' show FrameTiming;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Switching light and dark as a circular reveal: a picture of the old look
/// sits on top while the new theme is applied underneath, and a soft-edged
/// circle grows from the finger to show the new look. As it grows, the old
/// picture sinks back (scales down a touch, blurs and dims), and a faint
/// light rides the circle's edge, so the switch feels like depth rather
/// than a wipe.
class ThemeReveal {
  ThemeReveal._();

  /// True while a reveal is running; the app turns its own colour fade off so
  /// the two do not fight.
  static final ValueNotifier<bool> running = ValueNotifier(false);

  static _ThemeRevealHostState? _host;

  /// Applies [apply] (which changes the theme) with the circular reveal,
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
  static const duration = Duration(milliseconds: 820);

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
      // Start opening the circle first and change the theme a few frames in:
      // by then the window is a real shape and the old picture is certainly on
      // screen, so the new look only ever shows inside the circle.
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

  /// Width of the soft edge, in logical pixels.
  static const _feather = 90.0;

  @override
  void paint(Canvas canvas, Size size) {
    // The circle must grow past the farthest corner, plus its soft edge.
    final far = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((c) => (c - origin).distance).reduce((a, b) => a > b ? a : b);
    final eased = Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));
    final r = (far + _feather) * eased;

    final bounds = Offset.zero & size;
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    // The old look sinks back while the new one comes forward.
    final depth = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final scale = 1 - 0.05 * depth;
    final blur = 7.0 * depth;
    final dim = 0.18 * depth;

    canvas.saveLayer(bounds, Paint());

    // 1. The old picture, scaled toward the touch point, blurred and dimmed.
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
    canvas.translate(-origin.dx, -origin.dy);
    if (blur > 0.3) {
      canvas.saveLayer(
        bounds,
        Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      );
    }
    canvas.drawImageRect(image, src, bounds, Paint());
    if (dim > 0) {
      canvas.drawRect(bounds, Paint()..color = Color.fromRGBO(0, 0, 0, dim));
    }
    if (blur > 0.3) canvas.restore();
    canvas.restore();

    // 2. Cut the growing circle out of it with a soft, feathered edge. Until
    // the circle has a real size the old picture stays whole, so the new
    // theme can never flash through before the reveal starts.
    if (r > 1) {
      final inner = ((r - _feather) / r).clamp(0.0, 1.0);
      canvas.drawCircle(
        origin,
        r,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..shader = ui.Gradient.radial(
            origin,
            r,
            const [Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
            [0, inner, 1],
          ),
      );
    }
    canvas.restore();

    // 3. A faint light rides the edge and fades out as the circle grows.
    final glow = (1 - t).clamp(0.0, 1.0) * (t * 6).clamp(0.0, 1.0);
    if (r > 2 && glow > 0) {
      final edge = (r - _feather / 2).clamp(1.0, double.infinity);
      canvas.drawCircle(
        origin,
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 26
          ..color = Color.fromRGBO(255, 255, 255, 0.16 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
    }
  }

  @override
  bool shouldRepaint(_RevealPainter old) =>
      old.t != t || old.image != image || old.origin != origin;
}
