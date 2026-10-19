import 'package:calisthenics/features/workout/data/background_music.dart';
import 'package:calisthenics/features/workout/domain/music_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('music settings', () {
    test('music is on and 60% loud until the user changes it', () {
      expect(musicEnabledIn({}), isTrue);
      expect(musicVolumeIn({}), defaultMusicVolume);
      expect(defaultMusicVolume, 0.6);
    });

    test('the saved volume is read back and kept between 0 and 1', () {
      expect(musicVolumeIn({'musicVolume': 0.25}), 0.25);
      expect(musicVolumeIn({'musicVolume': 1}), 1.0);
      expect(musicVolumeIn({'musicVolume': 7}), 1.0);
      expect(musicVolumeIn({'musicVolume': -1}), 0.0);
      expect(musicVolumeIn({'musicVolume': 'loud'}), defaultMusicVolume);
      expect(musicEnabledIn({'musicEnabled': false}), isFalse);
    });
  });

  group('BackgroundMusic volume', () {
    test('starts at the default level', () {
      final m = BackgroundMusic();
      expect(m.targetVolume, BackgroundMusic.fullVolume);
    });

    test(
      'follows the slider, and drops to a share of it while a video talks',
      () {
        final m = BackgroundMusic();
        m.setLevel(1);
        expect(m.targetVolume, 1.0);
        m.setDucked(true);
        expect(m.targetVolume, closeTo(BackgroundMusic.duckedShare, 1e-9));
        m.setLevel(0.5);
        expect(
          m.targetVolume,
          closeTo(0.5 * BackgroundMusic.duckedShare, 1e-9),
        );
        m.setDucked(false);
        expect(m.targetVolume, 0.5);
      },
    );

    test('0 is silent, and out-of-range values are clamped', () {
      final m = BackgroundMusic();
      m.setLevel(0);
      expect(m.targetVolume, 0.0);
      m.setLevel(3);
      expect(m.targetVolume, 1.0);
      m.setLevel(-2);
      expect(m.targetVolume, 0.0);
    });
  });
}
