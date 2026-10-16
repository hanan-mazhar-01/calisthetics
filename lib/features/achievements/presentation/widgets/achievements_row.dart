import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/domain/achievement_evaluator.dart';
import '../screens/achievements_screen.dart';
import 'medal_badge.dart';

/// "Achievements — See All" and a sideways row of medals: what she has earned
/// (newest first), then the next medal to go for in each group.
class AchievementsRow extends StatelessWidget {
  const AchievementsRow({super.key, required this.achievements});
  final List<Achievement> achievements;

  List<Achievement> get _shown {
    final earned = achievements.where((a) => a.unlocked).toList()
      ..sort((a, b) {
        final x = a.unlockedAt, y = b.unlockedAt;
        if (x == null || y == null) return 0;
        return y.compareTo(x);
      });
    final next = <Achievement>[];
    for (final cat in AchievementCategory.values) {
      final locked =
          achievements.where((a) => a.category == cat && !a.unlocked).toList()
            ..sort((a, b) => a.target.compareTo(b.target));
      if (locked.isNotEmpty) next.add(locked.first);
    }
    return [...earned, ...next].take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final shown = _shown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Achievements',
                  style: AppTypography.title(
                    24,
                    c.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'See all achievements',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AchievementsScreen(),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'See All',
                      style: AppTypography.body(c.textMuted, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 152,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: shown.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final a = shown[i];
              final first = i == 0 && a.unlocked;
              return Semantics(
                button: true,
                label: '${a.title}, ${a.unlocked ? 'earned' : 'locked'}',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => a.unlocked
                      ? openMedal(context, a)
                      : Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AchievementsScreen(initialId: a.id),
                          ),
                        ),
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                    decoration: BoxDecoration(
                      gradient: first
                          ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                c.softRose.withValues(alpha: 0),
                                c.softRose.withValues(alpha: 0.9),
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        MedalBadge(
                          number: a.number,
                          unit: a.unit,
                          earned: a.unlocked,
                          size: 84,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          a.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTypography.body(
                            a.unlocked ? c.textPrimary : c.textMuted,
                            fontSize: 13,
                            weight: a.unlocked
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
