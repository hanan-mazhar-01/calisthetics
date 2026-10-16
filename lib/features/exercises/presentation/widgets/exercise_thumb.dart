import 'package:flutter/material.dart';

import '../../../media/data/media_manifest.dart';
import '../../../media/presentation/media_slot.dart';
import '../../domain/exercise_lookup.dart';

/// Square exercise thumbnail through the media seam. Until media is
/// configured it shows the labelled placeholder with the exercise name.
class ExerciseThumb extends StatelessWidget {
  const ExerciseThumb({
    super.key,
    required this.number,
    this.size = 64,
    this.radiusFactor = 0.25,
  });

  final int number;
  final double size;

  /// Corner radius as a share of [size]; 0 for edge-to-edge use inside a clipped card.
  final double radiusFactor;

  @override
  Widget build(BuildContext context) {
    final exercise = exerciseByNumber(number);
    return SizedBox(
      width: size,
      height: size,
      child: MediaSlot(
        slot: MediaSlotSpec('exercise-thumb-$number', exercise.name),
        borderRadius: BorderRadius.circular(size * radiusFactor),
        width: (size * 3).round(),
        compact: size < 64,
      ),
    );
  }
}
