import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/onboarding_controller.dart';
import 'name_step/glass_folder.dart';
import 'name_step/name_input_field.dart';
import 'name_step/pink_name_document.dart';

const _folderWidth = 112.0;
const _folderHeight = 146.0;
const _docWidth = 198.0;
const _docHeight = 134.0;
const _gap = 14.0;

/// Extra headroom above the folder so the document has room to rise out of
/// the tab/"mouth" before arcing right — without this the peak of the
/// emergence motion would be clipped by the layout above it.
const _topHeadroom = 34.0;

/// First-name capture, split into two distinct pieces on purpose: a plain
/// [NameInputField] below is where the user actually types, and a closed
/// glass folder sits above with nothing visible to its right. Focusing the
/// field is what opens the folder — a soft-pink [PinkNameDocument] rises out
/// of its mouth, arcs right, and live-mirrors whatever's typed below (it
/// never holds the real `TextField` itself, so there's nothing to keep in
/// sync besides a plain text listener). Continue plays a distinct — not
/// mirrored — closing motion, pulling the page back into the folder, before
/// [playCloseAnimation] resolves.
class NameStepContent extends ConsumerStatefulWidget {
  const NameStepContent({super.key});

  @override
  ConsumerState<NameStepContent> createState() => NameStepContentState();
}

class NameStepContentState extends ConsumerState<NameStepContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: ref.read(onboardingControllerProvider).name,
    )..addListener(_handleTextChanged);
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  void _handleTextChanged() {
    ref
        .read(onboardingControllerProvider.notifier)
        .setName(_textController.text);
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus && _controller.status != AnimationStatus.forward) {
      _controller.forward();
    }
  }

  /// Plays the folder-closing animation (document pulled back down into the
  /// folder's mouth) and only resolves once it's finished. Safe to call even
  /// if the folder was never opened.
  Future<void> playCloseAnimation() async {
    if (_controller.value == 0 && !_focusNode.hasFocus) return;
    if (_controller.status == AnimationStatus.reverse) return;
    _focusNode.unfocus();
    await _controller.reverse();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _textController.removeListener(_handleTextChanged);
    _textController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        AppSpacing.xl,
        AppSpacing.xxxl,
        AppSpacing.screenBottomCta,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _folderHeight + _topHeadroom,
            width: _folderWidth + _gap + _docWidth,
            child: AnimatedBuilder(
              animation: Listenable.merge([_controller, _textController]),
              builder: (context, _) {
                final isClosing = _controller.status == AnimationStatus.reverse;
                // `p` always reads as "how open" (0 closed -> 1 open). `tau`
                // is elapsed progress of *this* direction's play-through
                // (0 -> 1 either way), so the curve below actually shapes
                // time-as-experienced rather than fighting the controller's
                // own direction: decelerating into place on the way out,
                // accelerating — getting pulled in faster right at the end —
                // on the way in. Two distinct motions, not a mirrored one.
                final tau = isClosing
                    ? (1 - _controller.value)
                    : _controller.value;
                final p = isClosing
                    ? (1 - Curves.easeInCubic.transform(tau))
                    : Curves.easeOutCubic.transform(tau);

                final riseP = (p / 0.55).clamp(0.0, 1.0);
                final travelP = ((p - 0.25) / 0.75).clamp(0.0, 1.0);

                const mouthX = _folderWidth * 0.14;
                const mouthY = _topHeadroom + _folderHeight * 0.06;
                const peakY = 4.0;
                const restY = _topHeadroom + (_folderHeight - _docHeight) / 2;
                const restX = _folderWidth + _gap;

                final x = lerpDouble(mouthX, restX, travelP)!;
                final yRise = lerpDouble(mouthY, peakY, riseP)!;
                final y = lerpDouble(yRise, restY, travelP)!;
                final scale = lerpDouble(0.22, 1.0, p);
                final opacity = riseP;
                final tilt = lerpDouble(isClosing ? 0.14 : -0.18, 0.0, riseP)!;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (opacity > 0.01)
                      Positioned(
                        left: x,
                        top: y,
                        child: Opacity(
                          opacity: opacity,
                          child: Transform.rotate(
                            angle: tilt,
                            alignment: Alignment.bottomLeft,
                            child: Transform.scale(
                              scale: scale,
                              alignment: Alignment.bottomLeft,
                              child: PinkNameDocument(
                                width: _docWidth,
                                height: _docHeight,
                                name: _textController.text,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      top: _topHeadroom,
                      child: GlassFolder(
                        width: _folderWidth,
                        height: _folderHeight,
                        reactT: riseP,
                        openT: p,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          NameInputField(controller: _textController, focusNode: _focusNode),
          const SizedBox(height: AppSpacing.lg),
          Text(
            "We'll use this to greet you and in your milestones.",
            style: AppTypography.body(context.appColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
