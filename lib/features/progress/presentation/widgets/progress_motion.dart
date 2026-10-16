import 'package:flutter/material.dart';

import '../../../../core/motion/calesthetics_motion.dart';

/// True when the platform asks for no animation: show final states, run no loops.
bool reduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// One 0→1 clock for a whole group of staggered pieces (week circles, bars,
/// calendar cells…). The [builder] gets the raw progress `t` and slices it per
/// item with [staggerT]. With reduced motion it builds once at `t = 1`.
class StaggerClock extends StatelessWidget {
  const StaggerClock({
    super.key,
    required this.duration,
    required this.builder,
    this.delay = Duration.zero,
    this.curve = Curves.linear,
  });

  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Widget Function(BuildContext context, double t) builder;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return builder(context, 1);
    final total = delay + duration;
    final f = delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(f, 1, curve: curve),
      builder: (context, t, _) => builder(context, t),
    );
  }
}

/// Total clock length for [count] items that each take [span] and start
/// [step] after the previous one.
Duration staggerDuration(int count, {int stepMs = 60, int spanMs = 380}) =>
    Duration(milliseconds: (count <= 0 ? 0 : (count - 1) * stepMs) + spanMs);

/// Local 0→1 progress of item [i] (of [count]) inside a [StaggerClock] whose
/// duration came from [staggerDuration] with the same step/span.
double staggerT(
  double t,
  int i,
  int count, {
  int stepMs = 60,
  int spanMs = 380,
  Curve curve = Curves.easeOutCubic,
}) {
  final total = (count <= 0 ? 0 : (count - 1) * stepMs) + spanMs;
  final local = ((t * total - i * stepMs) / spanMs).clamp(0.0, 1.0);
  return curve.transform(local);
}

/// Card entrance: fade + rise, skipped under reduced motion.
class CardEntrance extends StatelessWidget {
  const CardEntrance({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    return CalestheticsFadeSlide(
      delay: Duration(milliseconds: 70 * index),
      child: child,
    );
  }
}

/// Delay after which a card's inner animation starts, so it plays once the
/// card has mostly arrived.
Duration innerDelay(int cardIndex) =>
    Duration(milliseconds: 70 * cardIndex + 160);
