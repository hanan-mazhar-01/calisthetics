import 'dart:async';

import 'package:calisthenics/core/haptics/haptics.dart';
import 'package:calisthenics/features/media/data/bunny_images.dart';
import 'package:calisthenics/features/media/data/exercise_videos.dart';
import 'package:calisthenics/features/workout/data/background_music.dart';

/// Runs before every test file: no widget test may reach the network.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  BunnyImages.enabled = false;
  ExerciseVideos.enabled = false;
  BackgroundMusic.enabled = false;
  Haptics.enabled = false;
  await testMain();
}
