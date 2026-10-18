import 'package:flutter/material.dart';

import '../../../../shared/widgets/bunny_image.dart';
import '../../../../shared/widgets/media_placeholder.dart';
import '../../domain/exercise.dart';

/// Bunny CDN key of an exercise's thumbnail: the exercise's own video file
/// name, so one name ties together the video and its picture.
String exerciseThumbnailKey(Exercise e) =>
    'thumbnails/${e.videoFile.replaceFirst(RegExp(r'\.mp4$'), '')}';

/// An exercise's thumbnail, filling its box. Until it loads (or if it can't)
/// the labelled placeholder shows.
class ExercisePicture extends StatelessWidget {
  const ExercisePicture({
    super.key,
    required this.exercise,
    this.compact = false,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  final Exercise exercise;
  final bool compact;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  /// Decode width in pixels. Small thumbnails (compact) default to 360,
  /// big pictures keep their full size.
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final placeholder = MediaPlaceholder(
      brief: exercise.name,
      compact: compact,
      borderRadius: borderRadius,
    );
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BunnyImage(
        exerciseThumbnailKey(exercise),
        fit: fit,
        cacheWidth: cacheWidth ?? (compact ? 360 : null),
        fallback: placeholder,
      ),
    );
  }
}
