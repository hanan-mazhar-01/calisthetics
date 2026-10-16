import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/onboarding_controller.dart';
import '../providers/plank_timer_controller.dart';

/// Live plank-hold test: a circular progress ring driven by a real
/// [Stopwatch] (see [PlankTimerController]) rather than a naive per-frame
/// counter, so the reading stays accurate regardless of jank.
class PlankStepContent extends ConsumerWidget {
  const PlankStepContent({super.key});

  (String lead, String body) _feedback(double seconds, int? previous) {
    if (seconds < 1) {
      return previous == null
          ? ('Ready.', 'Hold as long as you can with good form.')
          : ('Last result: ${previous}s.', 'Tap Retake to try again.');
    }
    if (seconds < 20) {
      return ('Every second counts.', 'Your plan builds holds gradually.');
    }
    if (seconds < 45) {
      return ('Solid start.', 'Holds get a little longer each week.');
    }
    return ('Strong hold.', 'That sets a good starting point.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(plankTimerControllerProvider);
    final controller = ref.read(plankTimerControllerProvider.notifier);
    final progress = (timer.elapsedSeconds / 60).clamp(0.0, 1.0);
    final label = timer.isRunning
        ? 'Stop'
        : (timer.elapsedSeconds > 0 ? 'Retake' : 'Start hold');
    final previous = ref.watch(
      onboardingControllerProvider.select((s) => s.plankSeconds),
    );
    final (lead, body) = _feedback(timer.elapsedSeconds, previous);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        AppSpacing.sm,
        AppSpacing.xxxl,
        AppSpacing.screenBottomCta,
      ),
      child: Column(
        children: [
          SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    backgroundColor: context.appColors.surfaceMuted,
                    valueColor: AlwaysStoppedAnimation(
                      context.appColors.accent,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timer.elapsedSeconds.toStringAsFixed(1),
                      style: AppTypography.display(
                        fontSize: 70,
                        color: context.appColors.textPrimary,
                        stretchPercent: 65,
                        height: 0.9,
                      ),
                    ),
                    Text(
                      'SECONDS',
                      style: AppTypography.kicker(
                        context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Material(
            color: context.appColors.textPrimary,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                final wasRunning = timer.isRunning;
                controller.toggle();
                if (wasRunning) {
                  final seconds = ref
                      .read(plankTimerControllerProvider)
                      .elapsedSeconds
                      .floor();
                  if (seconds > 0) {
                    ref
                        .read(onboardingControllerProvider.notifier)
                        .setPlankSeconds(seconds);
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 34,
                  vertical: 16,
                ),
                child: Text(
                  label,
                  style: AppTypography.title(
                    16,
                    context.appColors.onAccent,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: AppSpacing.xxl),
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: context.appColors.divider, width: 2),
              ),
            ),
            child: RichText(
              text: TextSpan(
                style: AppTypography.body(
                  context.appColors.textPrimary,
                  fontSize: 15,
                ),
                children: [
                  TextSpan(
                    text: '$lead ',
                    style: TextStyle(
                      color: context.appColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
