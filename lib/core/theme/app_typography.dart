import 'package:flutter/material.dart';

/// Typography tokens. Poppins is the app's font for every piece of text;
/// Lora (a soft serif) is used only for the highlighted pink word inside a
/// headline ([accentSerif]), as in the reference design.
///
/// Poppins draws heavier than the font it replaced, so the very heavy
/// weights are eased one step down to keep the same visual weight.
///
/// `stretchPercent` is kept as a parameter for call-site compatibility; it
/// has no effect (Poppins has no width axis).
abstract final class AppTypography {
  static TextStyle _base({
    required double fontSize,
    required FontWeight weight,
    required Color color,
    double? height,
    double letterSpacingEm = 0,
    double? stretchPercent,
  }) {
    return TextStyle(
      fontFamily: 'Poppins',
      fontSize: fontSize,
      fontWeight: switch (weight) {
        FontWeight.w900 => FontWeight.w600,
        FontWeight.w800 => FontWeight.w600,
        FontWeight.w700 => FontWeight.w600,
        _ => weight,
      },
      color: color,
      height: height,
      letterSpacing: letterSpacingEm * fontSize,
    );
  }

  /// Big display headline/number (hero titles, plan-number counters).
  /// Medium-semibold, like the reference headlines, with room between lines.
  static TextStyle display({
    required double fontSize,
    required Color color,
    double stretchPercent = 80,
    double height = 1.12,
    double letterSpacingEm = -0.02,
  }) {
    return _base(
      fontSize: fontSize,
      weight: FontWeight.w500,
      color: color,
      height: height,
      letterSpacingEm: letterSpacingEm,
      stretchPercent: stretchPercent,
    );
  }

  /// Section/card titles, exercise names.
  static TextStyle title(
    double fontSize,
    Color color, {
    FontWeight weight = FontWeight.w700,
    double height = 1.25,
  }) {
    return _base(
      fontSize: fontSize,
      weight: weight,
      color: color,
      height: height,
    );
  }

  /// Paragraph/body copy.
  static TextStyle body(
    Color color, {
    double fontSize = 15,
    double height = 1.45,
    FontWeight weight = FontWeight.w400,
  }) {
    return _base(
      fontSize: fontSize,
      weight: weight,
      color: color,
      height: height,
    );
  }

  /// Uppercase micro-labels/kickers (section eyebrows, step counters, badges).
  static TextStyle kicker(
    Color color, {
    double fontSize = 12,
    FontWeight weight = FontWeight.w700,
    double letterSpacingEm = 0.1,
  }) {
    return _base(
      fontSize: fontSize,
      weight: weight,
      color: color,
      height: 1.1,
      letterSpacingEm: letterSpacingEm,
    );
  }

  /// The highlighted word in a headline ("Where should we *focus*?"): Lora,
  /// in [color]. Merge it into the headline's own style so size and line
  /// height stay the same.
  static TextStyle accentSerif(Color color) {
    return TextStyle(
      fontFamily: 'Lora',
      color: color,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );
  }
}
