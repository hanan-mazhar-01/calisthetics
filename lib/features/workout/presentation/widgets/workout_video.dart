import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/bunny_image.dart';
import '../../../exercises/domain/exercise_lookup.dart';
import '../../../exercises/presentation/widgets/exercise_picture.dart';
import '../../../media/data/exercise_videos.dart';

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
    this.clip = false,
    this.sound = false,
  });

  final int exerciseNumber;
  final bool paused;

  /// Plays the exercise's short rest clip (always silent) instead of its
  /// 30 s video: used while she rests or sees what's up next.
  final bool clip;

  /// Plays the 30 s video's own sound.
  final bool sound;

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
    if (old.exerciseNumber != widget.exerciseNumber ||
        old.clip != widget.clip) {
      _load();
    } else if (old.paused != widget.paused || old.sound != widget.sound) {
      _syncPlayback();
    }
  }

  void _syncPlayback() {
    final c = _controller;
    if (c == null || !_ready) return;
    c.setVolume(widget.sound && !widget.clip ? 1 : 0);
    widget.paused ? c.pause() : c.play();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final old = _controller;
    _controller = null;
    _ready = false;
    await old?.dispose();
    if (!mounted || generation != _generation) return;
    final exercise = exerciseByNumber(widget.exerciseNumber);
    // While the clip plays during rest, the 30 s video is saved for the set.
    if (widget.clip) unawaited(ExerciseVideos.save(exercise));
    final controller = await ExerciseVideos.controller(
      exercise,
      clip: widget.clip,
    );
    if (!mounted || generation != _generation) {
      await controller?.dispose();
      return;
    }
    if (controller == null) {
      setState(() {});
      return;
    }
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || generation != _generation) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(widget.sound && !widget.clip ? 1 : 0);
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
        _VideoPlaceholder(
          name: name,
          thumbnailKey: exerciseThumbnailKey(
            exerciseByNumber(widget.exerciseNumber),
          ),
        ),
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
  const _VideoPlaceholder({required this.name, required this.thumbnailKey});
  final String name;
  final String thumbnailKey;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final label = DecoratedBox(
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
    // The exercise's thumbnail stands in while the clip loads; the plain
    // name card shows only if there is no picture either.
    return BunnyImage(thumbnailKey, fit: BoxFit.cover, fallback: label);
  }
}
