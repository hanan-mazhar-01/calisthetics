import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/media_placeholder.dart';
import '../data/media_manifest.dart';
import 'media_providers.dart';

/// A photo slot from the manifest. Shows the image when media is configured
/// and reachable; otherwise the labelled placeholder (never a broken box).
/// Images are disk-cached, so once seen they also work offline.
class MediaSlot extends ConsumerWidget {
  const MediaSlot({
    super.key,
    required this.slot,
    this.borderRadius,
    this.width,
    this.compact = false,
  });

  final MediaSlotSpec slot;
  final BorderRadius? borderRadius;

  /// Requested pixel width for delivery; omit to take the original size.
  final int? width;

  /// Small thumbnail: the placeholder shows an icon instead of its brief.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeholder = MediaPlaceholder(
      brief: slot.brief,
      borderRadius: borderRadius,
    );
    final url = ref.watch(mediaRepositoryProvider).image(slot.id, width: width);
    if (url == null) return placeholder;
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: url.toString(),
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }
}
