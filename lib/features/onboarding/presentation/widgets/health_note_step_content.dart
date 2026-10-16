import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../providers/onboarding_controller.dart';

const healthNoteStepId = 'health-note';
const healthNoteAcknowledged = 'acknowledged';

/// The health note: plain safety guidance plus an acknowledge checkbox. The
/// Continue button stays disabled until she ticks it.
class HealthNoteStepContent extends ConsumerWidget {
  const HealthNoteStepContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final acknowledged = ref.watch(
      onboardingControllerProvider.select(
        (s) => (s.selections[healthNoteStepId] ?? const <String>{}).contains(
          healthNoteAcknowledged,
        ),
      ),
    );
    const points = [
      (
        Icons.medical_services_outlined,
        'Talk to a doctor before you start if you are pregnant, injured or managing a medical condition.',
      ),
      (
        Icons.pan_tool_alt_outlined,
        'Stop right away if anything hurts. Rest, and choose an easier option next time.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        0,
        AppSpacing.xxl,
        AppSpacing.screenBottomCta,
      ),
      child: Column(
        children: [
          GlassCard(
            child: Column(
              children: [
                for (final (icon, text) in points)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: c.accentText),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Text(
                            text,
                            style: AppTypography.body(c.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassCard(
            selected: acknowledged,
            onTap: () {
              HapticFeedback.selectionClick();
              ref
                  .read(onboardingControllerProvider.notifier)
                  .toggleOption(
                    healthNoteStepId,
                    healthNoteAcknowledged,
                    multi: true,
                  );
            },
            child: Row(
              children: [
                Icon(
                  acknowledged
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: acknowledged ? c.accent : c.textMuted,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Text(
                    'I understand. I will train within my own limits.',
                    style: AppTypography.title(
                      15,
                      c.textPrimary,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
