import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/media_placeholder.dart';

/// Looping, muted demo video for one exercise. Owns exactly one
/// [VideoPlayerController] and disposes it. With a null [url] (media not
/// configured) or when [locked], shows the labelled placeholder instead and
/// creates no controller.
class ExerciseVideoSlot extends StatefulWidget {
  const ExerciseVideoSlot({
    super.key,
    required this.exerciseName,
    required this.url,
    this.locked = false,
    this.onLockedTap,
    this.aspectRatio = 4 / 5,
    this.onPlay,
  });

  final String exerciseName;
  final Uri? url;
  final bool locked;
  final VoidCallback? onLockedTap;
  final double aspectRatio;

  /// Shows a Play button on the video; it starts a 30-second try-out.
  final VoidCallback? onPlay;

  @override
  State<ExerciseVideoSlot> createState() => _ExerciseVideoSlotState();
}

class _ExerciseVideoSlotState extends State<ExerciseVideoSlot> {
  VideoPlayerController? _controller;
  bool _failed = false;

  bool get _shouldPlay => widget.url != null && !widget.locked;

  @override
  void initState() {
    super.initState();
    _setUp();
  }

  @override
  void didUpdateWidget(ExerciseVideoSlot old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url || old.locked != widget.locked) {
      _tearDown();
      _setUp();
    }
  }

  void _setUp() {
    if (!_shouldPlay) return;
    final controller = VideoPlayerController.networkUrl(widget.url!);
    _controller = controller;
    _failed = false;
    controller
        .initialize()
        .then((_) {
          if (!mounted || _controller != controller) return;
          controller
            ..setLooping(true)
            ..setVolume(0)
            ..play();
          setState(() {});
        })
        .catchError((Object _) {
          if (mounted && _controller == controller) {
            setState(() => _failed = true);
          }
        });
  }

  void _tearDown() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _tearDown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final radius = BorderRadius.circular(24);
    final controller = _controller;
    Widget child;
    if (controller != null && controller.value.isInitialized && !_failed) {
      child = ClipRRect(
        borderRadius: radius,
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      );
    } else {
      child = MediaPlaceholder(
        brief: '${widget.exerciseName}\nDemo video',
        borderRadius: radius,
      );
    }
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          if (widget.onPlay != null && !widget.locked)
            Center(
              child: Semantics(
                button: true,
                label: 'Play ${widget.exerciseName}',
                excludeSemantics: true,
                child: GestureDetector(
                  key: const ValueKey('exercise-play'),
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onPlay,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.accent,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 44,
                      color: c.onAccent,
                    ),
                  ),
                ),
              ),
            ),
          if (widget.locked)
            GestureDetector(
              onTap: widget.onLockedTap,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: c.cover.withValues(alpha: 0.45),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, color: c.onCover, size: 30),
                    const SizedBox(height: 6),
                    Text('Premium', style: AppTypography.title(15, c.onCover)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
