import 'package:flutter/animation.dart';

/// Centralized motion tokens. Every animated component should pull its
/// duration/curve from here rather than hardcoding — keeps motion consistent
/// and lets the whole app's "feel" be tuned from one place.
abstract final class AppDurations {
  /// Tactile taps: selection cards, buttons, checkmarks.
  static const Duration tap = Duration(milliseconds: 180);

  /// Selected-state transitions (border, background, scale settle).
  static const Duration selection = Duration(milliseconds: 300);

  /// Screen-to-screen content transitions within a flow (onboarding steps).
  static const Duration stepTransition = Duration(milliseconds: 420);

  /// Light <-> dark: every colour fades slowly and evenly, not in a flash.
  static const Duration themeSwitch = Duration(milliseconds: 800);

  /// Chart/ring/progress reveal animations.
  static const Duration reveal = Duration(milliseconds: 900);

  /// Long-form staged reveals (plan loading, milestone timelines).
  static const Duration staged = Duration(milliseconds: 1600);

  /// Workout timer tick granularity (never drives rebuild of the whole screen).
  static const Duration tick = Duration(milliseconds: 100);
}

abstract final class AppCurves {
  /// Default "premium" ease used for most UI transitions in the reference design.
  static const Curve standard = Cubic(0.2, 0.8, 0.2, 1);

  /// Overshoot used for checkmark reveals / selection pops.
  static const Curve overshoot = Cubic(0.3, 1.5, 0.5, 1);

  static const Curve linear = Curves.linear;
  static const Curve decelerate = Curves.easeOutCubic;
}
