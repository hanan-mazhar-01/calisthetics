import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/media_placeholder.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/onboarding_step.dart';
import 'onboarding_titled_header.dart';

/// Asymmetric 2-column photo mosaic ("Train anywhere", "Exercise library").
/// Alternating tiles sit a little higher to break the grid's rigidity.
class MosaicStepView extends StatelessWidget {
  const MosaicStepView({super.key, required this.step, required this.onNext});

  final MosaicStep step;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final left = <MosaicTile>[];
    final right = <MosaicTile>[];
    for (var i = 0; i < step.tiles.length; i++) {
      (i.isEven ? left : right).add(step.tiles[i]);
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                0,
                AppSpacing.xl,
                0,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OnboardingTitledHeader(headline: step.headline),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _MosaicColumn(tiles: left)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _MosaicColumn(tiles: right, offset: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxxl,
            0,
            AppSpacing.xxxl,
            AppSpacing.xxl,
          ),
          child: PrimaryButton(label: step.ctaLabel, onPressed: onNext),
        ),
      ],
    );
  }
}

class _MosaicColumn extends StatelessWidget {
  const _MosaicColumn({required this.tiles, this.offset = false});

  final List<MosaicTile> tiles;
  final bool offset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: offset ? 30 : 0),
      child: Column(
        children: [
          for (final tile in tiles)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: tile.height,
                  child: MediaPlaceholder(brief: tile.photoPrompt),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
