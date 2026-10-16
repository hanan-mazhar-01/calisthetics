/// Centralized spacing scale. Pulled from the recurring paddings observed
/// across the reference screens (card padding 16-24, hero/sheet safe-area 110-170).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 16;
  static const double xxl = 20;
  static const double xxxl = 24;

  /// Space reserved at the top of a titled/chrome screen for the sticky header.
  static const double screenTop = 110;

  /// Space reserved at the bottom of scrollable content so it clears the
  /// floating CTA / bottom tab bar.
  static const double screenBottomCta = 150;
}

/// Corner-radius scale. The design intentionally uses soft, large radii
/// (contrast this with any generic "Modernist" 0-radius system — not used here).
abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 28;
  static const double pill = 999;
}
