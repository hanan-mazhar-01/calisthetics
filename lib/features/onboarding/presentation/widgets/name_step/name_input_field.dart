import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors_extension.dart';
import '../../../../../core/theme/app_typography.dart';

/// The real, standalone name input — separate from [PinkNameDocument], which
/// only mirrors its text. Focusing this is what opens the folder.
class NameInputField extends StatelessWidget {
  const NameInputField({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: 1,
      textInputAction: TextInputAction.done,
      cursorColor: context.appColors.accent,
      style: AppTypography.title(
        18,
        context.appColors.textPrimary,
        weight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: 'Your first name',
        hintStyle: AppTypography.title(
          18,
          context.appColors.textMuted,
          weight: FontWeight.w600,
        ),
        filled: true,
        fillColor: context.appColors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: context.appColors.accent, width: 2),
        ),
      ),
    );
  }
}
