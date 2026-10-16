import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors_extension.dart';
import 'glass_folder_shape.dart';

/// White translucent glass folder — the closed resting state of the name
/// screen's hero visual. `reactT` (0-1) is the subtle tap-reaction progress:
/// a small scale pop and a hair of rotation, nothing more. `openT` (0-1) is
/// how "open" the folder currently is — it tints the inner paper hint pink
/// while the document is tucked inside, fading to plain white once it's
/// emerged (and back to pink as it's pulled back in on close).
class GlassFolder extends StatelessWidget {
  const GlassFolder({
    super.key,
    required this.width,
    required this.height,
    this.reactT = 0,
    this.openT = 0,
  });

  final double width;
  final double height;
  final double reactT;
  final double openT;

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + 0.035 * reactT;
    final angle = 0.018 * reactT;
    final paperColor = Color.lerp(
      context.appColors.softRose.withValues(alpha: 0.65),
      context.appColors.surface.withValues(alpha: 0.55),
      openT,
    )!;

    return Transform.rotate(
      angle: angle,
      child: Transform.scale(
        scale: scale,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Soft ambient shadow, drawn behind the folder's own clip so
              // it isn't cut off by the tab/body silhouette.
              Positioned(
                left: width * 0.06,
                right: width * 0.06,
                top: height * 0.22,
                bottom: -6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: context.appColors.textPrimary.withValues(
                          alpha: 0.14,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                ),
              ),
              ClipPath(
                clipper: const GlassFolderShape(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.appColors.surface.withValues(alpha: 0.85),
                            context.appColors.surface.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: const SizedBox.expand(),
                    ),
                    // Inner "paper" hint peeking from the body.
                    Positioned(
                      left: width * 0.14,
                      right: width * 0.14,
                      top: height * 0.32,
                      bottom: height * 0.1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: paperColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    // Glass highlight sweep.
                    Positioned(
                      left: -width * 0.2,
                      top: -height * 0.1,
                      width: width * 0.6,
                      height: height * 0.9,
                      child: Transform.rotate(
                        angle: -0.5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                context.appColors.surface.withValues(
                                  alpha: 0.35,
                                ),
                                context.appColors.surface.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: context.appColors.surface.withValues(
                            alpha: 0.65,
                          ),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
