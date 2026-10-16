import 'package:flutter/material.dart';

import '../../../core/theme/app_colors_extension.dart';

/// Round glass icon button for top bars (back, menu, notifications). Fake
/// glass — top bars that need real blur wrap their row in a `GlassSurface`.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.surface,
            border: Border.all(color: c.divider.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: c.textPrimary.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: size * 0.5, color: c.textPrimary),
        ),
      ),
    );
  }
}
