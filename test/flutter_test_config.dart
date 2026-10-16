import 'dart:async';

import 'package:calisthenics/features/media/data/bunny_images.dart';

/// Runs before every test file: no widget test may reach the network.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  BunnyImages.enabled = false;
  await testMain();
}
