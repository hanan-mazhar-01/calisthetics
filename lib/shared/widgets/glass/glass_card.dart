import 'package:flutter/material.dart';

import '../../../core/theme/app_colors_extension.dart';

/// Flat solid card: surface fill, hairline border, soft shadow. (Named
/// "glass" historically; the translucent/liquid look was removed app-wide.)
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.onTap,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: selected ? c.surfaceSelected : c.surface,
        border: Border.all(
          color: selected ? c.accent : c.divider.withValues(alpha: 0.6),
          width: selected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: c.textPrimary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(borderRadius: borderRadius, onTap: onTap, child: card),
    );
  }
}
