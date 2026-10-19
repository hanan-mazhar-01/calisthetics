import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// The workout's looping background track (assets/audio/gym_background_music.mp3).
///
/// It plays under the exercise videos and mixes with them (never takes the
/// audio focus, so the video's own coaching voice keeps playing). While a
/// video with sound plays it is "ducked" to a low volume, and it rises again
/// in rests. Every volume change fades. Turning music off only stops this
/// track; the video's voice is not affected. A missing file just means no
/// music: nothing here may break the workout.
class BackgroundMusic {
  BackgroundMusic();

  static const asset = 'audio/gym_background_music.mp3';

  /// Tests switch this off so no widget test touches the audio plugin.
  static bool enabled = true;

  /// The volume while nothing else is speaking, unless the user chose
  /// another with [setLevel]. While a video talks the music drops to this
  /// share of it.
  static const fullVolume = 0.6;
  static const duckedShare = 0.37;

  AudioPlayer? _player;
  bool _failed = false;
  bool _started = false;
  bool _disposed = false;

  bool _playing = false; // what the workout wants
  bool _ducked = false;
  double _level = fullVolume; // the user's volume (0 to 1)
  double _volume = 0; // what is sounding now
  Timer? _fade;

  /// Every platform call runs one after another, so quick pause/resume
  /// taps can never overtake each other.
  Future<void> _queue = Future.value();
  void _run(Future<void> Function() job) {
    _queue = _queue.then((_) async {
      if (_disposed || _failed || !enabled) return;
      try {
        await job();
      } catch (e) {
        debugPrint('Background music: $e');
      }
    });
  }

  double get _target => _ducked ? _level * duckedShare : _level;

  /// The volume the track is heading for right now.
  @visibleForTesting
  double get targetVolume => _target;

  /// Plays (fading in) or pauses (fading out) the track.
  void setPlaying(bool playing) {
    _playing = playing;
    _run(_apply);
  }

  /// The user's music volume, 0 to 1. Follows the slider at once (no fade);
  /// only this track changes, never the video's sound.
  void setLevel(double level) {
    final next = level.clamp(0.0, 1.0);
    if (next == _level) return;
    _level = next;
    _run(() async {
      if (!_playing || _player == null) return;
      _fade?.cancel();
      _volume = _target;
      await _player?.setVolume(_volume);
    });
  }

  /// Lowers the music while a video's own sound plays.
  void setDucked(bool ducked) {
    if (_ducked == ducked) return;
    _ducked = ducked;
    _run(_apply);
  }

  Future<void> _apply() async {
    if (_playing) {
      final p = await _open();
      if (p == null) return;
      if (!_started) {
        _started = true;
        await p.play(AssetSource(asset), volume: 0);
      } else if (p.state != PlayerState.playing) {
        await p.resume();
      }
      _fadeTo(_target);
    } else if (_player != null) {
      _fadeTo(0, thenPause: true);
    }
  }

  Future<AudioPlayer?> _open() async {
    final existing = _player;
    if (existing != null) return existing;
    try {
      final p = AudioPlayer();
      await p.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none, // mix with the video
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      await p.setReleaseMode(ReleaseMode.loop);
      _player = p;
      return p;
    } catch (e) {
      debugPrint('Background music unavailable: $e');
      _failed = true;
      return null;
    }
  }

  void _fadeTo(double to, {bool thenPause = false}) {
    _fade?.cancel();
    final from = _volume;
    const steps = 12; // ~600 ms
    var i = 0;
    _fade = Timer.periodic(const Duration(milliseconds: 50), (t) {
      i++;
      _volume = from + (to - from) * (i / steps);
      _player?.setVolume(_volume.clamp(0.0, 1.0)).catchError((_) {});
      if (i >= steps) {
        t.cancel();
        if (thenPause) {
          _run(() async {
            if (!_playing) await _player?.pause();
          });
        }
      }
    });
  }

  Future<void> dispose() async {
    _disposed = true;
    _fade?.cancel();
    final p = _player;
    _player = null;
    try {
      await p?.stop();
      await p?.dispose();
    } catch (_) {}
  }
}
