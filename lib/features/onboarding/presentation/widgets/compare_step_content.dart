import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../exercises/domain/exercise.dart';
import '../../../exercises/domain/exercise_lookup.dart';
import '../../../exercises/presentation/widgets/exercise_picture.dart';
import '../../domain/onboarding_step.dart';
import 'typewriter_text.dart';

/// "Built as a progression": a slowly turning 3D ring of the real Push-Up
/// ladder (all 8 rungs, easiest first), a meter that follows the rung in
/// front, then the old way struck through and the Calesthetics way ticked.
class CompareStepContent extends StatefulWidget {
  const CompareStepContent({super.key, required this.step});

  final CompareStep step;

  @override
  State<CompareStepContent> createState() => _CompareStepContentState();
}

class _CompareStepContentState extends State<CompareStepContent>
    with SingleTickerProviderStateMixin {
  static const _turn = Duration(seconds: 18);

  late final List<Exercise> _rungs = ladderFor('push-up');
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: _turn,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _spin.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        children: [
          StepReveal(
            index: 0,
            child: SizedBox(
              height: 178,
              child: AnimatedBuilder(
                animation: _spin,
                builder: (context, _) =>
                    _RungRing(rungs: _rungs, turn: _spin.value),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          StepReveal(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: AnimatedBuilder(
                animation: _spin,
                builder: (context, _) => _LadderMeter(
                  rungs: _rungs,
                  front: _RungRing.frontIndex(_spin.value, _rungs.length),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                for (var i = 0; i < 2 && i < step.leftItems.length; i++)
                  StepReveal(
                    index: 2 + i,
                    child: _Row(text: step.leftItems[i], good: false),
                  ),
                for (var i = 0; i < step.rightItems.length; i++)
                  StepReveal(
                    index: 4 + i,
                    child: _Row(text: step.rightItems[i], good: true),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The ladder's rungs as cards on a ring that turns around a vertical axis.
/// Cards in front are bigger and brighter; the far side sinks back.
class _RungRing extends StatelessWidget {
  const _RungRing({required this.rungs, required this.turn});

  final List<Exercise> rungs;

  /// 0 to 1: one full turn.
  final double turn;

  static const _cardW = 86.0;
  static const _cardH = 114.0;
  static const _radius = 116.0;

  /// The ring turns so rung 1, then 2, ... come to the front in order.
  static double _angle(int i, double turn, int count) =>
      2 * math.pi * (i / count - turn);

  /// Index of the rung nearest the front.
  static int frontIndex(double turn, int count) =>
      ((turn * count).round()) % count;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final count = rungs.length;
    final cards = <({double z, Widget w})>[];
    for (var i = 0; i < count; i++) {
      final a = _angle(i, turn, count);
      final x = math.sin(a) * _radius;
      final z = math.cos(a) * _radius; // +radius = front
      final depth = (z + _radius) / (2 * _radius); // 0 back .. 1 front
      final scale = 0.62 + 0.38 * depth;
      cards.add((
        z: z,
        w: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..translateByDouble(x, -10 * (1 - depth), 0, 1)
            ..rotateY(a)
            ..scaleByDouble(scale, scale, 1, 1),
          child: Opacity(
            opacity: (0.35 + 0.65 * depth).clamp(0.0, 1.0),
            child: _RungCard(
              exercise: rungs[i],
              number: i + 1,
              width: _cardW,
              height: _cardH,
            ),
          ),
        ),
      ));
    }
    cards.sort((a, b) => a.z.compareTo(b.z)); // back first, front on top
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // A soft rose pool of light under the ring.
        Positioned(
          bottom: 0,
          child: Container(
            width: 300,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: const BorderRadius.all(Radius.elliptical(150, 28)),
              gradient: RadialGradient(
                colors: [
                  c.accent.withValues(alpha: 0.26),
                  c.accent.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        for (final card in cards) card.w,
      ],
    );
  }
}

class _RungCard extends StatelessWidget {
  const _RungCard({
    required this.exercise,
    required this.number,
    required this.width,
    required this.height,
  });

  final Exercise exercise;
  final int number;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExercisePicture(exercise: exercise, compact: true),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 16, 6, 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
              child: Text(
                '$number · ${rungShortName(exercise)}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(
                  Colors.white,
                  fontSize: 11,
                  weight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Wall Push-Up" -> "Wall", "Assisted One-Arm Push-Up Progression" -> "One-arm".
String rungShortName(Exercise e) {
  if (e.name.toLowerCase().contains('one-arm')) return 'One-arm';
  return e.name.replaceAll(RegExp(r'\s*Push-Up.*$'), '');
}

/// The ladder as a row of dots, filled up to the rung in front.
class _LadderMeter extends StatelessWidget {
  const _LadderMeter({required this.rungs, required this.front});

  final List<Exercise> rungs;
  final int front;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final count = rungs.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: c.textPrimary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Push-Up ladder',
                  style: AppTypography.body(c.textSecondary, fontSize: 13),
                ),
              ),
              Text(
                'Rung ${front + 1} of $count · ${rungShortName(rungs[front])}',
                style: AppTypography.title(13, c.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, box) {
              final step = (box.maxWidth - 18) / (count - 1);
              return SizedBox(
                height: 18,
                child: Stack(
                  children: [
                    Positioned(
                      left: 9,
                      right: 9,
                      top: 5,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: c.surfaceSelected,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 9,
                      top: 5,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        width: step * front,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [c.softRose, c.accent],
                          ),
                        ),
                      ),
                    ),
                    for (var i = 0; i < count; i++)
                      Positioned(
                        left: step * i,
                        top: 0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i <= front ? c.accent : c.surface,
                            border: Border.all(
                              color: i <= front ? c.accent : c.softRose,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// One line of the comparison: the old way struck through, or the
/// Calesthetics way ticked.
class _Row extends StatelessWidget {
  const _Row({required this.text, required this.good});

  final String text;
  final bool good;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: good ? c.surface : c.surfaceMuted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: good
            ? [
                BoxShadow(
                  color: c.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: good ? c.accent : c.surfaceMuted,
            ),
            alignment: Alignment.center,
            child: Icon(
              good ? Icons.check_rounded : Icons.close_rounded,
              size: 14,
              color: good ? c.onAccent : c.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style:
                  AppTypography.body(
                    good ? c.textPrimary : c.textMuted,
                    fontSize: 14,
                    height: 1.3,
                  ).copyWith(
                    decoration: good ? null : TextDecoration.lineThrough,
                    decorationColor: c.textMuted,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
