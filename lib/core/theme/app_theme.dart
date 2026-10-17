import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_colors_extension.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles the app's light/dark [ThemeData]. This is the only file that
/// should construct a [ThemeData] — widgets read styling through
/// `Theme.of(context)` / `context.appColors`, never hardcoded hex values.
abstract final class AppTheme {
  static ThemeData get light => _build(brightness: Brightness.light);
  static ThemeData get dark => _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: AppColors.cta,
            onPrimary: AppColors.white,
            secondary: AppColors.darkAccent,
            onSecondary: AppColors.darkBackground,
            surface: AppColors.darkBackground,
            onSurface: AppColors.darkTextPrimary,
            surfaceContainerHighest: AppColors.darkSurface,
            onSurfaceVariant: AppColors.darkTextSecondary,
            outline: AppColors.darkDivider,
            error: Color(0xFFD98D8D),
            onError: AppColors.darkBackground,
          )
        : const ColorScheme.light(
            primary: AppColors.cta,
            onPrimary: AppColors.white,
            secondary: AppColors.brandRose,
            onSecondary: AppColors.white,
            surface: AppColors.lightBackground,
            onSurface: AppColors.textPrimary,
            surfaceContainerHighest: AppColors.lightSurface,
            onSurfaceVariant: AppColors.textSecondary,
            outline: AppColors.divider,
            error: Color(0xFFC1454F),
            onError: AppColors.white,
          );

    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;

    return ThemeData(
      useMaterial3: true,
      // Dialogs, snack bars, text fields and pickers use the app font too.
      fontFamily: 'Poppins',
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: [isDark ? AppColorsExtension.dark : AppColorsExtension.light],
      textTheme: TextTheme(
        headlineLarge: AppTypography.display(fontSize: 42, color: textColor),
        headlineMedium: AppTypography.display(fontSize: 33, color: textColor),
        titleLarge: AppTypography.title(20, textColor, weight: FontWeight.w800),
        titleMedium: AppTypography.title(17, textColor),
        bodyLarge: AppTypography.body(textColor),
        bodyMedium: AppTypography.body(
          colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
        labelSmall: AppTypography.kicker(colorScheme.onSurfaceVariant),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cta,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppTypography.title(
            17,
            AppColors.white,
            weight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkDivider : AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
