import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/motion/calesthetics_motion.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../exercises/domain/exercise_lookup.dart';
import '../../../exercises/presentation/widgets/exercise_thumb.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../providers/plan_providers.dart';

/// "Warm up · 4 Exercises" with the count in the accent colour.
class DaySectionHeader extends StatelessWidget {
  const DaySectionHeader({super.key, required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text.rich(
          TextSpan(
            style: AppTypography.title(18, c.textPrimary),
            children: [
              TextSpan(text: '$title · '),
              TextSpan(
                text: '$count ${count == 1 ? 'Exercise' : 'Exercises'}',
                style: TextStyle(color: c.accentText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One exercise: thumbnail, name, muted target. Opens exercise detail.
class DayExerciseRow extends StatelessWidget {
  const DayExerciseRow({
    super.key,
    required this.number,
    required this.target,
    this.index,
  });
  final int number;
  final String target;

  /// Position in the whole list; only the first few rows animate in.
  final int? index;

  static const int animatedRows = 10;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final exercise = exerciseByNumber(number);
    // A preview only: tapping a row does nothing. The session starts from
    // the Start button.
    Widget row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          ExerciseThumb(number: number, size: 56, radiusFactor: 0.2),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title(15, c.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  target,
                  style: AppTypography.body(c.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final i = index;
    if (i != null &&
        i < animatedRows &&
        !MediaQuery.disableAnimationsOf(context)) {
      row = CalestheticsFadeSlide(
        delay: Duration(milliseconds: 35 * i),
        duration: const Duration(milliseconds: 280),
        offset: 12,
        child: row,
      );
    }
    return row;
  }
}

/// Full-width START pill with a press-scale.
class DayStartBar extends StatefulWidget {
  const DayStartBar({super.key, required this.onStart, this.resume = false});
  final VoidCallback onStart;

  /// The day was left half-done: the button says RESUME.
  final bool resume;

  @override
  State<DayStartBar> createState() => _DayStartBarState();
}

class _DayStartBarState extends State<DayStartBar> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final still = MediaQuery.disableAnimationsOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.background.withValues(alpha: 0), c.background],
          stops: const [0, 0.35],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xxl,
          bottom + AppSpacing.lg,
        ),
        child: Semantics(
          button: true,
          label: widget.resume ? 'Resume workout' : 'Start workout',
          excludeSemantics: true,
          child: GestureDetector(
            key: const ValueKey('day-start'),
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _down = true),
            onTapCancel: () => setState(() => _down = false),
            onTapUp: (_) => setState(() => _down = false),
            onTap: widget.onStart,
            child: AnimatedScale(
              scale: _down && !still ? 0.97 : 1,
              duration: still
                  ? Duration.zero
                  : const Duration(milliseconds: 120),
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  widget.resume ? 'RESUME' : 'START',
                  style: AppTypography.title(16, c.onAccent),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rest-between-sets picker (settings key `restSeconds`).
Future<void> showDayRestSheet(BuildContext context) {
  final c = context.appColors;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.surface,
    showDragHandle: true,
    builder: (_) => const _RestSheet(),
  );
}

class _RestSheet extends ConsumerWidget {
  const _RestSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final selected = ref.watch(restSecondsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          0,
          AppSpacing.xxl,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rest between sets',
              style: AppTypography.title(20, c.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final v in const [10, 20, 30, 45])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '$v seconds',
                  style: AppTypography.title(15, c.textPrimary),
                ),
                trailing: v == selected
                    ? Icon(Icons.check_circle_rounded, color: c.accentText)
                    : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).set('restSeconds', v);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}
