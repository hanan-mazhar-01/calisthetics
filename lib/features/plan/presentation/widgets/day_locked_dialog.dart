import 'package:flutter/material.dart';

import '../../../../core/haptics/haptics.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';

/// Shown when a day is tapped before it has opened: a short, friendly note
/// saying it opens on its weekday ([opensOn]) or as soon as the day before
/// it ([finishDay]) is finished, and one button that closes it.
Future<void> showDayLockedDialog(
  BuildContext context, {
  required int finishDay,
  required int tappedDay,
  required String opensOn,
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
                'Day $tappedDay opens on $opensOn',
                textAlign: TextAlign.center,
                style: AppTypography.title(
                  22,
                  c.textPrimary,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'It opens on $opensOn, or sooner: as soon as you complete '
                'Day $finishDay. Each session builds on the one before.',
                textAlign: TextAlign.center,
                style: AppTypography.body(
                  c.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Semantics(
                container: true,
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
