import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../exercises/domain/exercise_lookup.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../widgets/profile_chrome.dart';

/// Exercises the user hearted.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final numbers = ref.watch(favoritesProvider).toList()..sort();
    return SubScreenScaffold(
      title: 'Favorites',
      children: [
        if (numbers.isEmpty)
          const EmptyCard(
            'No favorites yet. Tap the heart on any exercise to save it here.',
            icon: Icons.favorite_border_rounded,
          )
        else
          for (final n in numbers)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: GlassCard(
                onTap: () => context.push('/exercise/$n'),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exerciseByNumber(n).name,
                            style: AppTypography.title(15, c.textPrimary),
                          ),
                          Text(
                            exerciseByNumber(n).level.label,
                            style: AppTypography.body(
                              c.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove from favorites',
                      icon: Icon(Icons.favorite_rounded, color: c.accent),
                      onPressed: () =>
                          ref.read(favoritesProvider.notifier).toggle(n),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
