import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../user/presentation/providers/user_providers.dart';

/// Small read-only pill (level, equipment).
class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.surfaceMuted.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: c.textSecondary),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(
                c.textSecondary,
                fontSize: 12,
                weight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Favorite heart bound to [favoritesProvider].
class FavoriteHeart extends ConsumerWidget {
  const FavoriteHeart({super.key, required this.number, this.size = 24});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final isFav = ref.watch(
      favoritesProvider.select((s) => s.contains(number)),
    );
    return IconButton(
      tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
      visualDensity: VisualDensity.compact,
      onPressed: () => ref.read(favoritesProvider.notifier).toggle(number),
      icon: Icon(
        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: size,
        color: isFav ? c.accent : c.textMuted,
      ),
    );
  }
}
