import 'package:flutter/material.dart';

import '../../../../core/haptics/haptics.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';

/// Shown when a day is tapped before the one in front of it is finished: a
/// short, friendly note naming the day to finish first, and one button that
/// closes it.
Future<void> showDayLockedDialog(
  BuildContext context, {
  required int finishDay,
  required int tappedDay,
}) {
  Haptics.medium();
  return showDialog<void>(
    context: context,
    builder: (context) {
      final c = context.appColors;
      return Dialog(
        backgroundColor: c.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.softRose,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.lock_rounded, size: 30, color: c.accent),
              ),
              const SizedBox(height: 18),
              Text(
                'Finish Day $finishDay first',
                textAlign: TextAlign.center,
                style: AppTypography.title(
                  22,
                  c.textPrimary,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Day $tappedDay opens once you have completed Day $finishDay. '
                'Each session builds on the one before, so take them in order.',
                textAlign: TextAlign.center,
                style: AppTypography.body(
                  c.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Semantics(
                button: true,
                label: 'Got it',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 54,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Got it',
                      style: AppTypography.title(
                        16,
                        c.onAccent,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
