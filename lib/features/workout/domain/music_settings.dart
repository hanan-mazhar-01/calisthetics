/// Background-music settings, kept in the user's settings map.
const musicEnabledKey = 'musicEnabled';
const musicVolumeKey = 'musicVolume';

/// How loud the music is until the user moves the slider (0 to 1).
const defaultMusicVolume = 0.6;

bool musicEnabledIn(Map<String, dynamic> settings) =>
    (settings[musicEnabledKey] as bool?) ?? true;

/// The music volume, 0 (silent) to 1 (full). Only the background track: the
/// video's own sound is never touched.
double musicVolumeIn(Map<String, dynamic> settings) {
  final v = settings[musicVolumeKey];
  return v is num ? v.toDouble().clamp(0.0, 1.0) : defaultMusicVolume;
}
