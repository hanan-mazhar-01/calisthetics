import 'package:flutter/material.dart';

import '../../core/theme/app_colors_extension.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart' show AppRadius;
import '../../core/theme/app_typography.dart';

/// The design's recurring full-width CTA: a dark-rose stadium pill, 58px
/// tall, with a tactile press-scale (mirrors the source's
/// `style-active:"scale(.98)"`).
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final bool enabled;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled || widget.onPressed == null;
    final c = context.appColors;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: AppDurations.tap,
        curve: AppCurves.standard,
        child: AnimatedContainer(
          duration: AppDurations.selection,
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: disabled ? c.accent.withValues(alpha: 0.4) : c.accent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.label,
                    style: AppTypography.title(
                      17,
                      c.onAccent,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (widget.trailingIcon != null) const SizedBox(width: 12),
              if (widget.trailingIcon != null)
                Icon(widget.trailingIcon, color: c.onAccent, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
