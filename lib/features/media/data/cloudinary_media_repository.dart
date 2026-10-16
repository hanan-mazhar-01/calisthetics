import '../../exercises/domain/exercise.dart';
import '../domain/media_repository.dart';
import 'media_manifest.dart';

/// Builds delivery URLs for media hosted on Cloudinary. Only the public
/// cloud name is needed (it is in every delivery URL anyway); API keys and
/// secrets are never in the app — uploads happen from the dashboard or a
/// server.
class CloudinaryMediaRepository implements MediaRepository {
  const CloudinaryMediaRepository({required this.cloudName});

  final String cloudName;

  /// `q_auto` + `f_auto` let Cloudinary pick the smallest good format;
  /// `vc_auto` chooses the best codec per device.
  static const _videoTransform = 'q_auto,f_auto,vc_auto';

  String get _base => 'https://res.cloudinary.com/$cloudName';

  @override
  Uri? exerciseVideo(Exercise exercise) => Uri.parse(
    '$_base/video/upload/$_videoTransform/${_exerciseId(exercise)}.mp4',
  );

  @override
  Uri? exercisePoster(Exercise exercise) => Uri.parse(
    '$_base/video/upload/so_0,w_720,q_auto,f_auto/${_exerciseId(exercise)}.jpg',
  );

  @override
  Uri? image(String slotId, {int? width}) {
    final w = width == null ? '' : ',w_$width';
    return Uri.parse(
      '$_base/image/upload/q_auto,f_auto$w/${MediaPaths.slots}/$slotId',
    );
  }

  /// `calesthetics_001_wall_push_up_beginner_v1.mp4` → public id without extension.
  String _exerciseId(Exercise e) {
    final name = e.videoFile.replaceFirst(RegExp(r'\.mp4$'), '');
    return '${MediaPaths.exercises}/$name';
  }
}

/// Used until a Cloudinary cloud name is configured: nothing resolves, so
/// every slot shows its labelled placeholder rather than a broken image.
class UnconfiguredMediaRepository implements MediaRepository {
  const UnconfiguredMediaRepository();

  @override
  Uri? exerciseVideo(Exercise exercise) => null;
  @override
  Uri? exercisePoster(Exercise exercise) => null;
  @override
  Uri? image(String slotId, {int? width}) => null;
}
