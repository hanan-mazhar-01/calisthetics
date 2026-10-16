import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cloudinary_media_repository.dart';
import '../domain/media_repository.dart';

/// Public Cloudinary cloud name, supplied at build time:
/// `flutter run --dart-define=CLOUDINARY_CLOUD_NAME=your-cloud`.
const _cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return _cloudName.isEmpty
      ? const UnconfiguredMediaRepository()
      : const CloudinaryMediaRepository(cloudName: _cloudName);
});
