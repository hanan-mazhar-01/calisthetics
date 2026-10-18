import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';

/// Shown after signing in from the welcome screen when the account has no
/// finished plan yet: the account is ready, now set up the journey. The only
/// way out is "Get started", which continues into onboarding.
Future<void> showAccountReadyDialog(
  BuildContext context, {
  required bool isNew,
  String? email,
}) {
  HapticFeedback.mediumImpact();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final c = context.appColors;
      return PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: c.surface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
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
                  child: Icon(Icons.check_rounded, size: 34, color: c.accent),
                ),
                const SizedBox(height: 18),
                Text(
                  isNew ? 'Your account is ready' : 'Welcome back',
                  textAlign: TextAlign.center,
                  style: AppTypography.title(
                    22,
                    c.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
                if (email != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: AppTypography.body(c.textMuted, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  isNew
                      ? 'Now let’s start your journey. Answer a few '
                            'questions about your goals and preferences and '
                            'we’ll build your plan.'
                      : 'Your account has no plan yet. Answer a few '
                            'questions about your goals and preferences and '
                            'we’ll build it.',
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
                  label: 'Get started',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 54,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Get started',
                            style: AppTypography.title(
                              16,
                              c.onAccent,
                              weight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: c.onAccent,
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
      );
    },
  );
}
