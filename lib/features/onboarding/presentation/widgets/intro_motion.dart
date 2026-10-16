import 'package:flutter/material.dart';

/// Progress (0 to 1) of the slice [from]-[to] of a parent clock value [t].
double slice(
  double t,
  double from,
  double to, [
  Curve curve = Curves.easeOutCubic,
]) => curve.transform(((t - from) / (to - from)).clamp(0.0, 1.0));

/// Fades and slides [child] in during the slice [from]-[to] of [animation].
/// With [pop] it also grows from a smaller size with a little overshoot.
class IntroReveal extends StatelessWidget {
  const IntroReveal({
    super.key,
    required this.animation,
    required this.from,
    required this.to,
    required this.child,
    this.slide = const Offset(0, 16),
    this.pop = false,
  });

  final Animation<double> animation;
  final double from;
  final double to;
  final Widget child;

  /// Where it starts, in logical pixels away from its place.
  final Offset slide;
  final bool pop;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = slice(animation.value, from, to);
        if (t >= 1) return child!;
        final fade = slice(animation.value, from, from + (to - from) * 0.6);
        Widget out = Transform.translate(
          offset: Offset(slide.dx * (1 - t), slide.dy * (1 - t)),
          child: Opacity(opacity: fade, child: child),
        );
        if (pop) {
          final p = slice(animation.value, from, to, Curves.easeOutBack);
          out = Transform.scale(scale: 0.6 + 0.4 * p, child: out);
        }
        return out;
      },
    );
  }
}
