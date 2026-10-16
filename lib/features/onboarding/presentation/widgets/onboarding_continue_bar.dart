import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/primary_button.dart';

/// Floating bottom CTA, used by every step that doesn't auto-advance
/// (chapter dividers, multi-select questions, curve/chart screens). No
/// backing panel — just the button, sitting directly on the page.
class OnboardingContinueBar extends StatelessWidget {
  const OnboardingContinueBar({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        28,
        AppSpacing.xxxl,
        AppSpacing.xxl,
      ),
      child: PrimaryButton(
        label: label,
        enabled: enabled,
        onPressed: enabled ? onPressed : null,
        trailingIcon: Icons.arrow_forward_rounded,
      ),
    );
  }
}
