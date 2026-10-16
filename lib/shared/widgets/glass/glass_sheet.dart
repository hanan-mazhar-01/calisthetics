import 'package:flutter/material.dart';

import '../../../core/theme/app_colors_extension.dart';
import 'glass_surface.dart';

/// Bottom sheet on real glass. The one place (besides the tab bar and top
/// bars) where blur is allowed, because content sits beneath it.
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: context.appColors.cover.withValues(alpha: 0.35),
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: GlassSurface(
        borderRadius: const BorderRadius.all(Radius.circular(32)),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.appColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Ink effects (ListTile, checkboxes) need a Material under the solid surface.
            Material(type: MaterialType.transparency, child: builder(context)),
          ],
        ),
      ),
    ),
  );
}
