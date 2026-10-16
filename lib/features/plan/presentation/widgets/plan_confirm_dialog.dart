import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';

/// A confirm / cancel dialog in the app's own style, used before plan changes
/// that rebuild the workouts. Resolves to true only when she confirms.
Future<bool> showPlanConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? detail,
  required String confirmLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      final c = context.appColors;
      return Dialog(
        backgroundColor: c.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.title(
                  22,
                  c.textPrimary,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: AppTypography.body(c.textSecondary, fontSize: 15),
              ),
              if (detail != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.softRose,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    detail,
                    style: AppTypography.body(
                      c.textPrimary,
                      fontSize: 14,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: 'Cancel',
                      onTap: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogButton(
                      label: confirmLabel,
                      primary: true,
                      onTap: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return ok ?? false;
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary ? c.accent : c.surfaceMuted,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: AppTypography.title(
              16,
              primary ? c.onAccent : c.textPrimary,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
