import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic color tokens. Widgets read these through `context.appColors`
/// (never `AppColors.*`), so light and dark mode both resolve correctly.
///
/// Two families:
///  * page tokens (`background`, `surface`, `textPrimary`, ...) that flip with
///    the theme;
///  * `cover` tokens for surfaces that are deliberately dark in both modes
///    (welcome hero, premium, photo overlays) — same value in light and dark.
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceSelected,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.accent,
    required this.accentPressed,
    required this.accentText,
    required this.onAccent,
    required this.softRose,
    required this.success,
    required this.warning,
    required this.highlight,
    required this.cover,
    required this.coverSurface,
    required this.coverDivider,
    required this.coverHighlight,
    required this.onCover,
    required this.onCoverSecondary,
    required this.onCoverTertiary,
    required this.coverAccent,
  });

  /// Page background.
  final Color background;

  /// Cards, tiles, sheets sitting on the background.
  final Color surface;

  /// Quieter fills: inactive tracks, chips, placeholders.
  final Color surfaceMuted;

  /// Selected tile/card tint.
  final Color surfaceSelected;

  /// Headlines and body text.
  final Color textPrimary;

  /// Supporting text.
  final Color textSecondary;

  /// Captions, disabled and inactive labels.
  final Color textMuted;

  /// Hairlines and outlines.
  final Color divider;

  /// Brand fill: primary buttons, active indicators.
  final Color accent;

  /// Pressed state of [accent].
  final Color accentPressed;

  /// Brand-colored text/icons sitting directly on [background].
  final Color accentText;

  /// Text/icons placed on an [accent] fill.
  final Color onAccent;

  /// Soft brand tint: gradient washes, subtle fills.
  final Color softRose;

  /// Positive state.
  final Color success;

  /// Caution state.
  final Color warning;

  /// Callout background (PR highlights, achievement banners).
  final Color highlight;

  /// Intentionally dark surface in both modes (welcome, premium, photo overlays, compare card).
  final Color cover;

  /// Raised surface on a [cover].
  final Color coverSurface;

  /// Hairline on a [cover].
  final Color coverDivider;

  /// Callout fill on a [cover].
  final Color coverHighlight;

  /// Primary text on a [cover].
  final Color onCover;

  /// Secondary text on a [cover].
  final Color onCoverSecondary;

  /// Tertiary text on a [cover].
  final Color onCoverTertiary;

  /// Brand accent on a [cover].
  final Color coverAccent;

  static const light = AppColorsExtension(
    background: AppColors.lightBackground,
    surface: AppColors.white,
    surfaceMuted: AppColors.lightSurface,
    surfaceSelected: AppColors.lightSurfaceSelected,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    divider: AppColors.divider,
    accent: AppColors.cta,
    accentPressed: AppColors.ctaPressed,
    accentText: AppColors.cta,
    onAccent: AppColors.white,
    softRose: AppColors.softRose,
    success: AppColors.success,
    warning: AppColors.warning,
    highlight: AppColors.softRose,
    cover: AppColors.darkBackground,
    coverSurface: AppColors.darkSurface,
    coverDivider: AppColors.darkDivider,
    coverHighlight: AppColors.darkHighlight,
    onCover: AppColors.darkTextPrimary,
    onCoverSecondary: AppColors.darkTextSecondary,
    onCoverTertiary: AppColors.darkTextTertiary,
    coverAccent: AppColors.darkAccent,
  );

  static const dark = AppColorsExtension(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceMuted: AppColors.darkSurfaceMuted,
    surfaceSelected: AppColors.darkHighlight,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textMuted: AppColors.darkTextMuted,
    divider: AppColors.darkDivider,
    accent: AppColors.cta,
    accentPressed: AppColors.ctaPressed,
    accentText: AppColors.darkAccent,
    onAccent: AppColors.white,
    softRose: AppColors.darkHighlight,
    success: AppColors.success,
    warning: AppColors.warning,
    highlight: AppColors.darkHighlight,
    cover: AppColors.darkBackground,
    coverSurface: AppColors.darkSurface,
    coverDivider: AppColors.darkDivider,
    coverHighlight: AppColors.darkHighlight,
    onCover: AppColors.darkTextPrimary,
    onCoverSecondary: AppColors.darkTextSecondary,
    onCoverTertiary: AppColors.darkTextTertiary,
    coverAccent: AppColors.darkAccent,
  );

  /// Dark scrim for legibility over photos/video; same in both modes.
  Color scrim(double opacity) => cover.withValues(alpha: opacity);

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceSelected,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? divider,
    Color? accent,
    Color? accentPressed,
    Color? accentText,
    Color? onAccent,
    Color? softRose,
    Color? success,
    Color? warning,
    Color? highlight,
    Color? cover,
    Color? coverSurface,
    Color? coverDivider,
    Color? coverHighlight,
    Color? onCover,
    Color? onCoverSecondary,
    Color? onCoverTertiary,
    Color? coverAccent,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceSelected: surfaceSelected ?? this.surfaceSelected,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      divider: divider ?? this.divider,
      accent: accent ?? this.accent,
      accentPressed: accentPressed ?? this.accentPressed,
      accentText: accentText ?? this.accentText,
      onAccent: onAccent ?? this.onAccent,
      softRose: softRose ?? this.softRose,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      highlight: highlight ?? this.highlight,
      cover: cover ?? this.cover,
      coverSurface: coverSurface ?? this.coverSurface,
      coverDivider: coverDivider ?? this.coverDivider,
      coverHighlight: coverHighlight ?? this.coverHighlight,
      onCover: onCover ?? this.onCover,
      onCoverSecondary: onCoverSecondary ?? this.onCoverSecondary,
      onCoverTertiary: onCoverTertiary ?? this.onCoverTertiary,
      coverAccent: coverAccent ?? this.coverAccent,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceSelected: Color.lerp(surfaceSelected, other.surfaceSelected, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentPressed: Color.lerp(accentPressed, other.accentPressed, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      softRose: Color.lerp(softRose, other.softRose, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      cover: Color.lerp(cover, other.cover, t)!,
      coverSurface: Color.lerp(coverSurface, other.coverSurface, t)!,
      coverDivider: Color.lerp(coverDivider, other.coverDivider, t)!,
      coverHighlight: Color.lerp(coverHighlight, other.coverHighlight, t)!,
      onCover: Color.lerp(onCover, other.onCover, t)!,
      onCoverSecondary: Color.lerp(
        onCoverSecondary,
        other.onCoverSecondary,
        t,
      )!,
      onCoverTertiary: Color.lerp(onCoverTertiary, other.onCoverTertiary, t)!,
      coverAccent: Color.lerp(coverAccent, other.coverAccent, t)!,
    );
  }
}

/// Convenience accessor: `context.appColors.textPrimary`.
extension AppColorsContext on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>()!;
}
