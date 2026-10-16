import 'package:flutter/material.dart';

import '../../core/theme/app_colors_extension.dart';
import '../../core/theme/app_typography.dart';

/// Stand-in for a future photo/video asset slot (mirrors the design's
/// `<image-slot placeholder="...">`). Shows the asset brief so content gaps
/// stay visible and intentional instead of rendering a bare gray/"PHOTO" box.
/// Swap the `child` for an `Image`/`VideoPlayer` once real media lands —
/// call sites don't need to change.
class MediaPlaceholder extends StatelessWidget {
  const MediaPlaceholder({
    super.key,
    required this.brief,
    this.borderRadius,
    this.circular = false,
    this.compact = false,
  });

  final String brief;
  final BorderRadius? borderRadius;
  final bool circular;

  /// For small thumbnails: show an icon instead of the (unreadable) brief.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return ClipRRect(
      borderRadius: circular
          ? BorderRadius.circular(9999)
          : (borderRadius ?? BorderRadius.zero),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.softRose, c.surfaceMuted],
          ),
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.all(compact ? 0 : 10),
        child: compact
            ? Icon(
                Icons.fitness_center_rounded,
                size: 20,
                color: c.accentText.withValues(alpha: 0.7),
              )
            : Text(
                brief,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(
                  c.textSecondary,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
      ),
    );
  }
}
