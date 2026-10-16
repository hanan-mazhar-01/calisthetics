import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'bunny_images.dart';

/// Downloads every image under [prefix] into the disk cache, one at a time,
/// without decoding them (so it costs bandwidth, not memory). Later screens
/// then show their pictures instantly, and they work offline. Failures are
/// ignored: a missed image just loads when its screen opens.
Future<void> prefetchBunnyImages(String prefix) async {
  if (!BunnyImages.enabled) return;
  final cache = DefaultCacheManager();
  for (final key in BunnyImages.keysUnder(prefix)) {
    final url = BunnyImages.url(key);
    if (url == null) continue;
    try {
      await cache.getSingleFile(url.toString());
    } catch (_) {}
  }
}
