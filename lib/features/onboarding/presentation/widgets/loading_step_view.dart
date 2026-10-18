import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/media_placeholder.dart';
import '../../../exercises/domain/exercise_lookup.dart';
import '../../../exercises/presentation/widgets/exercise_picture.dart';
import '../../domain/onboarding_step.dart';
import '../widgets/onboarding_continue_bar.dart';

/// Animated "building your plan" screen: a progress counter driving staged
/// status text. The plan itself is built locally from the user's answers, so
/// this is a short pause to let the moment land; it shows no rating or
/// social proof.
class LoadingStepView extends StatefulWidget {
  const LoadingStepView({super.key, required this.step, required this.onNext});

  final LoadingStep step;
  final VoidCallback onNext;

  @override
  State<LoadingStepView> createState() => _LoadingStepViewState();
}

class _LoadingStepViewState extends State<LoadingStepView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final percent = (_controller.value * 100).floor();
        // Short phones (iPhone SE class): a smaller number, less space above
        // and no exercise strip, so everything fits without scrolling.
        final short = MediaQuery.sizeOf(context).height < 760;
        return Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xxxl,
                  short ? 56 : 110,
                  AppSpacing.xxxl,
                  AppSpacing.xxl,
                ),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1,
                    colors: [
                      context.appColors.softRose,
                      context.appColors.softRose.withValues(alpha: 0),
                    ],
                    stops: [0, 0.7],
                  ),
                  color: context.appColors.background,
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUILDING YOUR PLAN',
                        style: AppTypography.kicker(
                          context.appColors.accent,
                          letterSpacingEm: 0.12,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.display(
                            fontSize: short ? 84 : 120,
                            color: context.appColors.textPrimary,
                            stretchPercent: 62,
                            letterSpacingEm: -0.04,
                          ),
                          children: [
                            TextSpan(text: '$percent'),
                            TextSpan(
                              text: '%',
                              style: AppTypography.display(
                                fontSize: short ? 34 : 48,
                                color: context.appColors.accent,
                                stretchPercent: 62,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: _controller.value,
                          minHeight: 6,
                          backgroundColor: context.appColors.surfaceMuted,
                          valueColor: AlwaysStoppedAnimation(
                            context.appColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      for (var i = 0; i < widget.step.stages.length; i++)
                        _StageRow(
                          label: widget.step.stages[i],
                          index: i,
                          percent: percent,
                        ),
                      if (!short) const SizedBox(height: AppSpacing.xl),
                      if (!short)
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.step.previewExercises.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: AppSpacing.md),
                            itemBuilder: (context, i) => SizedBox(
                              width: 120,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SizedBox(
                                      height: 90,
                                      child: _previewPicture(
                                        widget.step.previewExercises[i],
                                        i < widget.step.previewNumbers.length
                                            ? widget.step.previewNumbers[i]
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.step.previewExercises[i],
                                    style: AppTypography.body(
                                      context.appColors.textPrimary,
                                      fontSize: 13,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            OnboardingContinueBar(
              label: 'Continue',
              enabled: _controller.isCompleted,
              onPressed: widget.onNext,
            ),
          ],
        );
      },
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.label,
    required this.index,
    required this.percent,
  });

  final String label;
  final int index;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final threshold = (index + 1) * 16.6;
    final isDone = percent >= threshold;
    final isActive = !isDone && percent >= index * 16.6;
    final color = isDone
        ? context.appColors.textPrimary
        : (isActive
              ? context.appColors.accentText
              : context.appColors.textMuted);
    final dot = isDone
        ? context.appColors.accent
        : (isActive
              ? context.appColors.softRose
              : context.appColors.surfaceMuted);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: AnimatedScale(
              scale: isDone ? 1 : 0,
              duration: AppDurations.selection,
              curve: AppCurves.overshoot,
              child: Icon(
                Icons.check_rounded,
                size: 12,
                color: context.appColors.onAccent,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(
                color,
                fontSize: 16,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The exercise's thumbnail for the "building your plan" preview, or the
/// labelled placeholder when the name isn't in the catalog.
Widget _previewPicture(String name, int? number) {
  final exercise = number == null ? null : exerciseByNumber(number);
  return exercise == null
      ? MediaPlaceholder(brief: name)
      : ExercisePicture(exercise: exercise);
}
