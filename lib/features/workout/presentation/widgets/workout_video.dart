import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/bunny_image.dart';
import '../../../exercises/domain/exercise.dart';
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
    this.onLoading,
  });

  final int exerciseNumber;
  final bool paused;

  /// Plays the exercise's short rest clip (always silent) instead of its
  /// 30 s video: used while she rests or sees what's up next.
  final bool clip;

  /// Plays the 30 s video's own sound.
  final bool sound;

  /// Told when the video starts (true) and finishes (false) loading, so the
  /// workout timer can wait for it.
  final ValueChanged<bool>? onLoading;

  @override
  ConsumerState<WorkoutVideo> createState() => _WorkoutVideoState();
}

class _WorkoutVideoState extends ConsumerState<WorkoutVideo> {
  VideoPlayerController? _controller;
  bool _ready = false;
  int _generation = 0;

  /// The set's 30 s video, initialised (paused) while its rest clip plays,
  /// so the set starts on a ready video instead of a loading picture.
  VideoPlayerController? _warm;
  String? _warmKey;

  String _key(int exercise, bool clip) => '$exercise-$clip';

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

  /// Shows [next] in place of the current video; the old one is disposed
  /// only after the new one is on screen, so nothing blank shows between.
  void _swapIn(VideoPlayerController next) {
    widget.onLoading?.call(false);
    final old = _controller;
    setState(() {
      _controller = next;
      _ready = true;
    });
    _syncPlayback();
    if (!widget.paused) next.play();
    if (old != null && old != next) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final exercise = exerciseByNumber(widget.exerciseNumber);
    final key = _key(widget.exerciseNumber, widget.clip);
    widget.onLoading?.call(ExerciseVideos.has(exercise));

    // The set's video was already warmed up during the rest clip.
    final warm = _warm;
    if (warm != null && _warmKey == key && warm.value.isInitialized) {
      _warm = null;
      _warmKey = null;
      _swapIn(warm);
      return;
    }

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
      widget.onLoading?.call(false);
      final old = _controller;
      setState(() {
        _controller = null;
        _ready = false;
      });
      await old?.dispose();
      return;
    }
    try {
      // The previous video keeps playing until this one is ready.
      await controller.initialize();
      if (!mounted || generation != _generation) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(widget.sound && !widget.clip ? 1 : 0);
      _swapIn(controller);
      if (widget.clip) unawaited(_warmUp(exercise, generation));
    } catch (_) {
      await controller.dispose();
      if (generation == _generation) widget.onLoading?.call(false);
      if (mounted && generation == _generation && _controller == null) {
        setState(() {});
      }
    }
  }

  /// Gets the set's 30 s video ready (paused, silent) behind the rest clip.
  Future<void> _warmUp(Exercise exercise, int generation) async {
    final key = _key(exercise.number, false);
    if (_warmKey == key) return;
    final previous = _warm;
    _warm = null;
    _warmKey = null;
    await previous?.dispose();
    final c = await ExerciseVideos.controller(exercise);
    if (c == null) return;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      if (!mounted || generation != _generation) {
        await c.dispose();
        return;
      }
      _warm = c;
      _warmKey = key;
    } catch (_) {
      await c.dispose();
    }
  }

  @override
  void dispose() {
    _generation++;
    _controller?.dispose();
    _controller = null;
    _warm?.dispose();
    _warm = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final exercise = exerciseByNumber(widget.exerciseNumber);
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
    // The exercise has a video that is still loading: show the video's own
    // plain studio backdrop (not a different photo) with a thin loading bar,
    // so the video appears without a jump.
    if (ExerciseVideos.has(exercise)) {
      return const Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: _videoBackdrop),
          _Buffering(),
        ],
      );
    }
    // No video for this exercise: its thumbnail, or the name.
    return _VideoPlaceholder(
      name: exercise.name,
      thumbnailKey: exerciseThumbnailKey(exercise),
    );
  }
}

/// The light studio grey the exercise videos are filmed against.
const _videoBackdrop = Color(0xFFDBD3CA);

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
