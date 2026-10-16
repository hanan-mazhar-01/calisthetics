/// A named place in the UI that shows a photo. The id is also the Cloudinary
/// public id (under `calesthetics/slots/`), so adding a photo is: upload it
/// with that id — no app release needed.
class MediaSlotSpec {
  const MediaSlotSpec(this.id, this.brief, {this.aspectRatio});

  final String id;

  /// What the photo should show; rendered on the placeholder until it exists.
  final String brief;
  final double? aspectRatio;
}

const mediaSlots = <MediaSlotSpec>[
  MediaSlotSpec(
    'welcome-hero',
    'Woman training outdoors at sunrise, full-body, calm and strong',
    aspectRatio: 9 / 16,
  ),
  MediaSlotSpec(
    'photo-question-hero',
    'Woman mid-skill on a bar, candid, natural light',
    aspectRatio: 9 / 16,
  ),
  MediaSlotSpec(
    'focus-figure',
    'Full-length athletic woman, front view, neutral stance',
    aspectRatio: 0.45,
  ),
  MediaSlotSpec(
    'plan-hero',
    'Woman finishing a workout, smiling, studio light',
    aspectRatio: 4 / 5,
  ),
  MediaSlotSpec(
    'home-today-hero',
    'Woman training at home, wide shot',
    aspectRatio: 16 / 10,
  ),
];

/// Cloudinary folder layout. Keep in sync with docs/MEDIA.md.
abstract final class MediaPaths {
  static const exercises = 'calesthetics/exercises';
  static const slots = 'calesthetics/slots';
}
