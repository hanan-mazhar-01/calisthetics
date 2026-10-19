import 'package:flutter/material.dart';

import '../../../../core/haptics/haptics.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';

/// After joining a plan: "Switch the plan now?". Resolves to true for
/// "Switch now"; "Not now" (or tapping outside) keeps the current plan.
Future<bool> showSwitchPlanDialog(
  BuildContext context, {
  required String planName,
}) async {
  Haptics.medium();
  final switchNow = await showDialog<bool>(
    context: context,
    builder: (context) {
      final c = context.appColors;
      Widget button(String label, bool primary) => Semantics(
        container: true,
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(primary),
          child: Container(
            height: 52,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary ? c.accent : c.surfaceMuted,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: AppTypography.title(
                15.5,
                primary ? c.onAccent : c.textSecondary,
                weight: FontWeight.w700,
              ).copyWith(letterSpacing: 0.4),
            ),
          ),
        ),
      );
      return Dialog(
        backgroundColor: c.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Switch the plan now?',
                textAlign: TextAlign.center,
                style: AppTypography.title(
                  21,
                  c.textPrimary,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  style: AppTypography.body(
                    c.textSecondary,
                    fontSize: 14.5,
                    height: 1.45,
                  ),
                  children: [
                    const TextSpan(text: "You've joined "),
                    TextSpan(
                      text: "'$planName'",
                      style: TextStyle(
                        color: c.accentText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(
                      text:
                          '! Do you want to switch to it as your current plan '
                          'right now?',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              button('SWITCH NOW', true),
              const SizedBox(height: 10),
              button('NOT NOW', false),
            ],
          ),
        ),
      );
    },
  );
  return switchNow ?? false;
}
