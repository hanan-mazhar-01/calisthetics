import 'package:flutter/material.dart';

/// Raw brand color constants for the Calesthetics brand design.
/// Only `lib/core/theme/` may reference these. Widgets use `context.appColors`
/// ([AppColorsExtension]) so light/dark switching stays centralized.
abstract final class AppColors {
  // Light surfaces
  static const Color lightBackground = Color(0xFFF7F7F7);
  static const Color lightSurface = Color(0xFFF3E9E8);
  static const Color lightSurfaceSelected = Color(0xFFF7E1E4);
  static const Color lightSurfaceMuted = Color(0xFFE8DCDC);

  // Brand rose
  static const Color brandRose = Color(0xFFD96C7A);
  static const Color cta = Color(0xFFD85F70);
  static const Color ctaPressed = Color(0xFFB94A5B);
  static const Color softRose = Color(0xFFF1C6CB);

  // Text (light mode)
  static const Color textPrimary = Color(0xFF191719);
  static const Color textSecondary = Color(0xFF746D70);
  static const Color textMuted = Color(0xFFBDB1B3);
  static const Color divider = Color(0xFFDED5D5);

  // Semantic
  static const Color success = Color(0xFF789078);
  static const Color warning = Color(0xFFD99A65);

  // Dark surfaces
  static const Color darkBackground = Color(0xFF171516);
  static const Color darkSurface = Color(0xFF242021);
  static const Color darkDivider = Color(0xFF353032);
  static const Color darkSurfaceMuted = Color(0xFF2D292B);
  static const Color darkHighlight = Color(0xFF4A3035);

  // Text (dark mode)
  static const Color darkTextPrimary = Color(0xFFFAF6F4);
  static const Color darkTextSecondary = Color(0xFFAAA1A3);
  static const Color darkTextMuted = Color(0xFF8A8184);
  static const Color darkTextTertiary = Color(0xFFD9CFD1);
  static const Color darkAccent = Color(0xFFE27A88);

  static const Color white = Color(0xFFFFFFFF);
}
