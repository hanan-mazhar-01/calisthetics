import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/onboarding_step.dart';
import 'onboarding_chrome.dart' show chapterNames;

/// Screen 3/12/25/33: chapter-divider screen — big chapter number, headline,
/// and a 4-row table-of-contents showing Done/Now/upcoming across the whole
/// onboarding journey (not just the current chapter).
class PartIntroStepView extends StatelessWidget {
  const PartIntroStepView({super.key, required this.step});

  final PartIntroStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.1,
          colors: [context.appColors.softRose, Color(0x00F1C6CB)],
          stops: [0, 0.6],
        ),
        color: context.appColors.background,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxxl,
          110,
          AppSpacing.xxxl,
          140,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step.chapterNumberLabel,
              style: AppTypography.display(
                fontSize: 150,
                color: context.appColors.accent,
                stretchPercent: 62,
                letterSpacingEm: -0.04,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            RichText(
              text: TextSpan(
                style: AppTypography.display(
                  fontSize: 42,
                  color: context.appColors.textPrimary,
                  stretchPercent: 85,
                ),
                children: [
                  TextSpan(text: step.headline.lead),
                  TextSpan(
                    text: step.headline.accent,
                    style: TextStyle(color: context.appColors.accentText),
                  ),
                  TextSpan(text: step.headline.tail),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              step.subtitle,
              style: AppTypography.body(context.appColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ...List.generate(4, (i) {
              final chapterNum = i + 1;
              final isDone = chapterNum < step.chapter!;
              final isNow = chapterNum == step.chapter;
              final fg = isNow
                  ? context.appColors.accentText
                  : (isDone
                        ? context.appColors.textPrimary
                        : context.appColors.textMuted);
              final line = isNow
                  ? context.appColors.accentText
                  : context.appColors.divider;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: line, width: 2)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '0$chapterNum',
                        style: AppTypography.title(
                          20,
                          fg,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        chapterNames[chapterNum] ?? '',
                        style: AppTypography.title(18, fg),
                      ),
                    ),
                    Text(
                      isDone ? 'Done' : (isNow ? 'Now' : ''),
                      style: AppTypography.kicker(fg, letterSpacingEm: 0.06),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
