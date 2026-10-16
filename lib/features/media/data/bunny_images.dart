import 'bunny_image_versions.g.dart';

/// Delivery URLs for the app's still images, served from Bunny's CDN.
///
/// Only the public CDN host lives in the app; the storage key is used by
/// `tool/bunny_upload_images.py` on a developer machine and is never shipped.
/// Override the host with `--dart-define=BUNNY_IMAGE_HOST=...`.
abstract final class BunnyImages {
  static const host = String.fromEnvironment(
    'BUNNY_IMAGE_HOST',
    defaultValue: 'calisthetics-images.b-cdn.net',
  );

  /// Tests switch this off so no widget test touches the network.
  static bool enabled = true;

  /// `onboarding/goal-screen/get-stronger` -> the CDN URL, or null when
  /// images are off. The content hash is part of the file name, so a
  /// replaced picture has a new URL and is never served stale (CDN or device).
  static Uri? url(String key) {
    if (!enabled || host.isEmpty) return null;
    final version = bunnyImageVersions[key];
    return Uri.https(
      host,
      version == null ? '/$key.webp' : '/$key.$version.webp',
    );
  }

  /// Every known image key under [prefix] (e.g. `onboarding/`).
  static Iterable<String> keysUnder(String prefix) =>
      bunnyImageVersions.keys.where((k) => k.startsWith(prefix));
}
