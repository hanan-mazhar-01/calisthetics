import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../features/media/data/bunny_images.dart';

/// A still image from the Bunny CDN, by key (`onboarding/goal-screen/knee`).
///
/// Disk-cached, so once seen it also works offline. While it loads, and if
/// it can't be loaded, [fallback] shows instead (never a broken box).
class BunnyImage extends StatelessWidget {
  const BunnyImage(
    this.imageKey, {
    super.key,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.fallback,
  });

  final String imageKey;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final url = BunnyImages.url(imageKey);
    final empty = fallback ?? const SizedBox.shrink();
    if (url == null) return empty;
    return CachedNetworkImage(
      imageUrl: url.toString(),
      fit: fit,
      alignment: alignment,
      fadeInDuration: const Duration(milliseconds: 180),
      fadeOutDuration: Duration.zero,
      placeholder: (_, _) => const SizedBox.shrink(),
      errorWidget: (_, _, _) => empty,
    );
  }
}
