import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/onboarding_step.dart';

/// Vertical milestone timeline. Each row fades/slides in with a stagger
/// proportional to its position, so the journey reads top-to-bottom instead
/// of appearing all at once.
class MilestonesStepContent extends StatefulWidget {
  const MilestonesStepContent({super.key, required this.step});

  final MilestonesStep step;

  @override
  State<MilestonesStepContent> createState() => _MilestonesStepContentState();
}

class _MilestonesStepContentState extends State<MilestonesStepContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final milestones = widget.step.milestones;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        0,
        AppSpacing.xxxl,
        AppSpacing.screenBottomCta,
      ),
      child: Column(
        children: [
          for (var i = 0; i < milestones.length; i++)
            _MilestoneRow(
              milestone: milestones[i],
              isLast: i == milestones.length - 1,
              isCurrent: i == 3,
              isPast: i < 3,
              animation: CurvedAnimation(
                parent: _controller,
                curve: Interval(
                  (i * 0.15).clamp(0, 1),
                  (0.4 + i * 0.15).clamp(0, 1),
                  curve: Curves.easeOut,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.milestone,
    required this.isLast,
    required this.isCurrent,
    required this.isPast,
    required this.animation,
  });

  final Milestone milestone;
  final bool isLast;
  final bool isCurrent;
  final bool isPast;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final dotColor = isCurrent
        ? context.appColors.accent
        : (isPast ? context.appColors.textPrimary : context.appColors.softRose);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 16),
            child: child,
          ),
        );
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: context.appColors.divider,
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.lg, bottom: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      milestone.week,
                      style: AppTypography.kicker(context.appColors.accentText),
                    ),
                    Text(
                      milestone.label,
                      style: AppTypography.title(
                        21,
                        context.appColors.textPrimary,
                        weight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      milestone.description,
                      style: AppTypography.body(
                        context.appColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
