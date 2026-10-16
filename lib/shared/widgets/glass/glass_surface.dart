import 'package:flutter/material.dart';

import '../../../core/theme/app_colors_extension.dart';

/// Flat, opaque surface used for the tab bar, top bars and sheets. (The name
/// is historical: the frosted-glass blur was removed app-wide, so this is a
/// plain card with a hairline border and a soft shadow.)
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.padding,
    // Kept so existing call sites compile; blur/opacity no longer apply.
    double blur = 0,
    double opacity = 1,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: c.surface,
        border: Border.all(color: c.divider.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: c.textPrimary.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
