import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors_extension.dart';
import '../../../../../core/theme/app_typography.dart';

/// The soft-pink glass "page" that rises out of [GlassFolder]'s mouth — a
/// pure live display of whatever's been typed into the separate
/// [NameInputField] below. It never holds the real `TextField` itself, just
/// mirrors its text, so the two can sit in visually distinct places.
class PinkNameDocument extends StatelessWidget {
  const PinkNameDocument({
    super.key,
    required this.width,
    required this.height,
    required this.name,
  });

  final double width;
  final double height;
  final String name;

  @override
  Widget build(BuildContext context) {
    final hasName = name.trim().isNotEmpty;
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.appColors.surface.withValues(alpha: 0.7),
            context.appColors.softRose.withValues(alpha: 0.55),
          ],
        ),
        border: Border.all(
          color: context.appColors.surface.withValues(alpha: 0.75),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: context.appColors.accent.withValues(alpha: 0.16),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'YOUR NAME',
                style: AppTypography.kicker(
                  context.appColors.accentText,
                  letterSpacingEm: 0.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasName ? name : 'Your name',
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: AppTypography.display(
                  fontSize: 24,
                  color: hasName
                      ? context.appColors.textPrimary
                      : context.appColors.textMuted,
                  stretchPercent: 85,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
