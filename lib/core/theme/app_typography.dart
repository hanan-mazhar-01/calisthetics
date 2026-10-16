import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens, all routed through Manrope — premium, editorial,
/// highly readable, the single global font for the whole app.
///
/// `stretchPercent` is kept as a parameter for call-site compatibility with
/// the display styles that used to request Archivo's variable "width" axis;
/// Manrope's variable font only exposes a weight axis, so this is a no-op
/// here (safely ignored) rather than a visual regression.
abstract final class AppTypography {
  static TextStyle _base({
    required double fontSize,
    required FontWeight weight,
    required Color color,
    double? height,
    double letterSpacingEm = 0,
    double? stretchPercent,
  }) {
    return GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacingEm * fontSize,
    );
  }

  /// Big condensed display headline/number (hero titles, plan-number counters).
  /// `stretchPercent` mirrors the source CSS `font-stretch` value (62-92).
  static TextStyle display({
    required double fontSize,
    required Color color,
    double stretchPercent = 80,
    double height = 0.95,
    double letterSpacingEm = -0.03,
  }) {
    return _base(
      fontSize: fontSize,
      weight: FontWeight.w800,
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
}
