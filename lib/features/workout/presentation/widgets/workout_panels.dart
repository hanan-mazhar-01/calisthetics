import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';

/// Real blur over the video, tinted with the dark cover surface so the
/// cover text tokens stay readable in both themes.
class CoverGlass extends ConsumerWidget {
  const CoverGlass({super.key, required this.child, this.radius = 28});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final r = BorderRadius.circular(radius);
    final box = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        color: c.coverSurface,
        border: Border.all(color: c.coverDivider),
      ),
      child: child,
    );
    return box;
  }
}

class CoverButton extends StatelessWidget {
  const CoverButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.icon,
  });
  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final fg = primary ? c.cover : c.onCover;
    return Material(
      color: primary ? c.coverAccent : c.coverHighlight,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppTypography.title(16, fg)),
            ],
          ),
        ),
      ),
    );
  }
}
