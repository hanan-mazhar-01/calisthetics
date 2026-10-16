import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/onboarding_step.dart';
import 'intro_motion.dart';
import 'onboarding_titled_header.dart';

/// "What's inside" plan summary: key/value rows plus a muscle-group
/// allocation breakdown, each bar animating in on first build.
class PlanContentStepView extends StatefulWidget {
  const PlanContentStepView({
    super.key,
    required this.step,
    required this.onNext,
  });

  final PlanContentStep step;
  final VoidCallback onNext;

  @override
  State<PlanContentStepView> createState() => _PlanContentStepViewState();
}

class _PlanContentStepViewState extends State<PlanContentStepView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // With animations turned off, show the finished screen at once.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  IntroReveal(
                    animation: _controller,
                    from: 0,
                    to: 0.08,
                    slide: const Offset(0, 10),
                    child: OnboardingTitledHeader(
                      headline: widget.step.headline,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxxl,
                    ),
                    child: Column(
                      children: [
                        for (var r = 0; r < widget.step.rows.length; r++)
                          IntroReveal(
                            animation: _controller,
                            from: 0.07 + r * 0.045,
                            to: 0.07 + r * 0.045 + 0.13,
                            slide: const Offset(36, 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: context.appColors.divider,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    widget.step.rows[r].key,
                                    style: AppTypography.body(
                                      context.appColors.textSecondary,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.lg),
                                  Flexible(
                                    child: Text(
                                      widget.step.rows[r].value,
                                      textAlign: TextAlign.end,
                                      style: AppTypography.title(
                                        15,
                                        context.appColors.textPrimary,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (widget.step.calendar.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxl),
                          _WeekCalendar(
                            days: widget.step.calendar,
                            note: widget.step.calendarNote,
                            animation: _controller,
                            start:
                                0.07 + widget.step.rows.length * 0.045 + 0.06,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xxxl),
                        for (
                          var m = 0;
                          m < widget.step.muscleAllocations.length;
                          m++
                        )
                          _AllocationBar(
                            allocation: widget.step.muscleAllocations[m],
                            animation: _controller,
                            start: 0.52 + m * 0.1,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IntroReveal(
          animation: _controller,
          from: 0.9,
          to: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxxl,
              0,
              AppSpacing.xxxl,
              AppSpacing.xxl,
            ),
            child: PrimaryButton(
              label: widget.step.ctaLabel,
              onPressed: widget.onNext,
            ),
          ),
        ),
      ],
    );
  }
}

/// One muscle-group bar: the label fades in, then the bar fills and shows the
/// share as it grows.
class _AllocationBar extends StatelessWidget {
  const _AllocationBar({
    required this.allocation,
    required this.animation,
    required this.start,
  });

  final MuscleAllocation allocation;
  final Animation<double> animation;
  final double start;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: IntroReveal(
        animation: animation,
        from: start,
        to: start + 0.1,
        slide: const Offset(0, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              allocation.label,
              style: AppTypography.body(
                c.textPrimary,
                fontSize: 14,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedBuilder(
              animation: animation,
              builder: (context, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value:
                      allocation.fraction *
                      slice(
                        animation.value,
                        start + 0.04,
                        start + 0.2,
                        Curves.easeInOutCubic,
                      ),
                  minHeight: 8,
                  backgroundColor: c.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation(c.accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekCalendar extends StatelessWidget {
  const _WeekCalendar({
    required this.days,
    required this.animation,
    required this.start,
    this.note,
  });

  final List<CalendarDay> days;
  final String? note;
  final Animation<double> animation;
  final double start;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < days.length; i++)
              _DayDot(
                day: days[i],
                animation: animation,
                // Circles pop in one by one; training days then fill in.
                start: start + i * 0.028,
              ),
          ],
        ),
        if (note != null) ...[
          const SizedBox(height: AppSpacing.md),
          IntroReveal(
            animation: animation,
            from: start + days.length * 0.028 + 0.1,
            to: start + days.length * 0.028 + 0.18,
            slide: const Offset(0, 6),
            child: Text(
              note!,
              style: AppTypography.body(c.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.day,
    required this.animation,
    required this.start,
  });

  final CalendarDay day;
  final Animation<double> animation;
  final double start;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final pop = slice(
          animation.value,
          start,
          start + 0.07,
          Curves.easeOutBack,
        );
        final fill = day.isTraining
            ? slice(animation.value, start + 0.06, start + 0.14)
            : 0.0;
        final base = c.surfaceMuted;
        return Opacity(
          opacity: slice(animation.value, start, start + 0.04),
          child: Transform.scale(
            scale: 0.4 + 0.6 * pop,
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(base, c.accent, fill),
              ),
              child: Text(
                day.label,
                style: AppTypography.title(
                  14,
                  Color.lerp(
                    c.textMuted,
                    c.onAccent,
                    day.isTraining ? fill : 0,
                  )!,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
