import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

import '../../exercises/domain/exercise.dart';
import 'bunny_videos.g.dart';

/// Exercise videos on Bunny Stream.
///
/// The first time a video plays it streams (HLS: the quality follows the
/// connection, like YouTube) while its 720p MP4 is saved on the phone in the
/// background; every later play is from that file, with no internet needed.
///
/// Only the public CDN host and video ids are in the app; the upload key
/// stays on the developer machine (tool/bunny_upload_videos.py).
abstract final class ExerciseVideos {
  static const host = String.fromEnvironment(
    'BUNNY_STREAM_HOST',
    defaultValue: 'vz-7e6c48c2-251.b-cdn.net',
  );

  /// The library refuses requests without a referrer.
  static const headers = {'Referer': 'https://calisthetics.app/'};

  /// Tests switch this off so no widget test touches the network.
  static bool enabled = true;

  static final _cache = CacheManager(
    Config(
      'exercise_videos',
      // ~100 exercises x (video + clip): room for all of them.
      maxNrOfCacheObjects: 260,
      stalePeriod: const Duration(days: 120),
    ),
  );
  static final _downloading = <String, Future<void>>{};

  /// Saved (or found saved) during this run: no need to check again.
  static final _saved = <String>{};

  static String _stem(Exercise e) => e.videoFile.replaceFirst('.mp4', '');

  /// Bunny id of the exercise's 30 s video, or its 10 s rest [clip].
  static String? idFor(Exercise e, {bool clip = false}) {
    if (!enabled || host.isEmpty) return null;
    final ids = bunnyVideos[_stem(e)];
    if (ids == null) return null;
    return clip ? (ids.$2 ?? ids.$1) : (ids.$1 ?? ids.$2);
  }

  static bool has(Exercise e) => idFor(e) != null;

  /// Whether a video for [e] was uploaded at all (ignores [enabled]): used
  /// to decide if the page offers a Play button.
  static bool exists(Exercise e) => bunnyVideos.containsKey(_stem(e));

  static Uri _hls(String id) => Uri.https(host, '/$id/playlist.m3u8');
  static Uri _mp4(String id) => Uri.https(host, '/$id/play_720p.mp4');

  /// A controller for the exercise's video (not yet initialised), or null
  /// when it has none. Plays from the phone when saved, else streams.
  static Future<VideoPlayerController?> controller(
    Exercise e, {
    bool clip = false,
  }) async {
    final id = idFor(e, clip: clip);
    if (id == null) return null;
    final options = VideoPlayerOptions(mixWithOthers: true);
    final file = await _savedFile(id);
    if (file != null) {
      return VideoPlayerController.file(file, videoPlayerOptions: options);
    }
    unawaited(save(e, clip: clip));
    return VideoPlayerController.networkUrl(
      _hls(id),
      httpHeaders: headers,
      formatHint: VideoFormat.hls,
      videoPlayerOptions: options,
    );
  }

  static Future<File?> _savedFile(String id) async {
    try {
      final info = await _cache.getFileFromCache(_mp4(id).toString());
      return info?.file;
    } catch (_) {
      return null;
    }
  }

  /// Saves the video on the phone (no-op when it already is, or is being
  /// saved). Used to get the next exercise ready ahead of time.
  static Future<void> save(Exercise e, {bool clip = false}) {
    final id = idFor(e, clip: clip);
    if (id == null) return Future.value();
    final url = _mp4(id).toString();
    if (_saved.contains(url)) return Future.value();
    return _downloading[url] ??= () async {
      try {
        if (await _cache.getFileFromCache(url) == null) {
          await _cache.downloadFile(url, authHeaders: headers);
        }
        _saved.add(url);
      } catch (_) {
        // Offline or not ready yet: it simply streams next time.
      } finally {
        _downloading.remove(url);
      }
    }();
  }

  /// Deletes every saved video (Profile > Clear downloaded videos).
  static Future<void> clearSaved() {
    _saved.clear();
    return _cache.emptyCache();
  }
}
