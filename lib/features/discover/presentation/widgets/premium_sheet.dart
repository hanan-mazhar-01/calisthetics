import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/glass_sheet.dart';
import '../../../../shared/widgets/primary_button.dart';

/// "Premium" sheet shown when a locked item is tapped; its button opens
/// the paywall.
Future<void> showPremiumSheet(
  BuildContext context, {
  String message = 'Unlock every ladder, video and plan with Premium.',
}) {
  final router = GoRouter.of(context);
  return showGlassSheet<void>(
    context,
    builder: (sheetContext) {
      final c = sheetContext.appColors;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, color: c.accent, size: 28),
          const SizedBox(height: 10),
          Text('Premium', style: AppTypography.title(22, c.textPrimary)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body(c.textSecondary),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'See Premium',
            onPressed: () {
              Navigator.of(sheetContext).pop();
              router.push('/paywall');
            },
          ),
        ],
      );
    },
  );
}
