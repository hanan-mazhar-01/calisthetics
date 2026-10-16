import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Calesthetics' small reusable motion toolkit. Every "this screen/element just
/// appeared" reveal in the app should go through [CalestheticsFadeSlide] rather than
/// a one-off `AnimationController`, so the whole app shares one consistent
/// entrance language: fade + a short rise, delayed by hierarchy rather than
/// animated all at once.
///
/// Built on [TweenAnimationBuilder] (not a controller) because the motion is
/// purely a function of "time since this widget mounted" — no external state
/// drives it, so there's nothing to dispose and nothing that re-triggers on
/// an unrelated parent rebuild (the tween's `end` never changes, so Flutter
/// only plays it once per mount).
class CalestheticsFadeSlide extends StatelessWidget {
  const CalestheticsFadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 320),
    this.offset = 18,
    this.curve = AppCurves.decelerate,
  });

  final Widget child;

  /// How long to hold at the pre-entrance state before animating — this is
  /// what lets a screen's chrome, headline, content and CTA settle in one
  /// after another instead of popping in together.
  final Duration delay;
  final Duration duration;

  /// Vertical rise distance in logical pixels, travelled upward into place.
  final double offset;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final total = duration + delay;
    final delayFraction = total.inMicroseconds == 0
        ? 0.0
        : (delay.inMicroseconds / total.inMicroseconds).clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(delayFraction, 1, curve: curve),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * offset),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Staggers [CalestheticsFadeSlide] across a list of children by a fixed per-item
/// offset — for a short run of cards/rows entering together (e.g. the skill
/// picker), not for long lists where a growing delay would feel sluggish.
class CalestheticsStaggeredList extends StatelessWidget {
  const CalestheticsStaggeredList({
    super.key,
    required this.children,
    this.itemDelay = const Duration(milliseconds: 40),
    this.itemDuration = const Duration(milliseconds: 320),
    this.offset = 16,
    this.maxDelaySteps = 6,
  });

  final List<Widget> children;
  final Duration itemDelay;
  final Duration itemDuration;
  final double offset;

  /// Caps how many steps of delay stack up, so item 20 in a long list isn't
  /// still waiting to appear — it just joins the last wave.
  final int maxDelaySteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i++)
          CalestheticsFadeSlide(
            delay: itemDelay * i.clamp(0, maxDelaySteps),
            duration: itemDuration,
            offset: offset,
            child: children[i],
          ),
      ],
    );
  }
}
