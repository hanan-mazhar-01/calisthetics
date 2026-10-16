import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../exercises/domain/exercise_lookup.dart';
import '../../../media/presentation/media_providers.dart';

/// Looping demo of one exercise. Holds at most ONE
/// [VideoPlayerController]: when the exercise changes the old one is
/// disposed before the new one starts. Because the player shows the upcoming
/// exercise during preview/rest, the next video is initialised while the user
/// recovers and just keeps playing when the set begins. With no media (or a
/// load error) it shows a labelled placeholder with the exercise name.
class WorkoutVideo extends ConsumerStatefulWidget {
  const WorkoutVideo({
    super.key,
    required this.exerciseNumber,
    required this.paused,
  });

  final int exerciseNumber;
  final bool paused;

  @override
  ConsumerState<WorkoutVideo> createState() => _WorkoutVideoState();
}

class _WorkoutVideoState extends ConsumerState<WorkoutVideo> {
  VideoPlayerController? _controller;
  bool _ready = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(WorkoutVideo old) {
    super.didUpdateWidget(old);
    if (old.exerciseNumber != widget.exerciseNumber) {
      _load();
    } else if (old.paused != widget.paused) {
      _syncPlayback();
    }
  }

  void _syncPlayback() {
    final c = _controller;
    if (c == null || !_ready) return;
    widget.paused ? c.pause() : c.play();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final old = _controller;
    _controller = null;
    _ready = false;
    await old?.dispose();
    if (!mounted || generation != _generation) return;
    final url = ref
        .read(mediaRepositoryProvider)
        .exerciseVideo(exerciseByNumber(widget.exerciseNumber));
    if (url == null) {
      setState(() {});
      return;
    }
    final controller = VideoPlayerController.networkUrl(
      url,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || generation != _generation) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);
      setState(() => _ready = true);
      _syncPlayback();
      if (!widget.paused) await controller.play();
    } catch (_) {
      if (_controller == controller) _controller = null;
      await controller.dispose();
      if (mounted && generation == _generation) setState(() {});
    }
  }

  @override
  void dispose() {
    _generation++;
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final name = exerciseByNumber(widget.exerciseNumber).name;
    if (controller != null && _ready) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.contain,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: controller,
            builder: (_, v, _) =>
                v.isBuffering ? const _Buffering() : const SizedBox.shrink(),
          ),
        ],
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        _VideoPlaceholder(name: name),
        // A URL exists and the clip is still preparing: thin pre-roll bar.
        if (controller != null) const _Buffering(),
      ],
    );
  }
}

class _Buffering extends StatelessWidget {
  const _Buffering();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Align(
      alignment: Alignment.topCenter,
      child: LinearProgressIndicator(
        minHeight: 3,
        color: c.accent,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.surface, c.softRose],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: AppTypography.title(
              26,
              c.textSecondary,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
