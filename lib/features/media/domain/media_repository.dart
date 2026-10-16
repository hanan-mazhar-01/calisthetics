import '../../exercises/domain/exercise.dart';

/// Resolves where media lives. The app never builds media URLs itself —
/// everything goes through this seam, so swapping hosts (or serving from an
/// offline cache) touches one class.
abstract interface class MediaRepository {
  /// Streaming URL of an exercise's demo video, or null when media isn't
  /// configured (UI then shows a labelled placeholder).
  Uri? exerciseVideo(Exercise exercise);

  /// First-frame poster for the same exercise.
  Uri? exercisePoster(Exercise exercise);

  /// A still image for a named slot from the media manifest.
  Uri? image(String slotId, {int? width});
}
