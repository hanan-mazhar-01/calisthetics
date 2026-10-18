import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../achievements/presentation/screens/achievements_screen.dart';
import '../../../calendar/presentation/screens/day_activity_screen.dart';
import '../../../calendar/presentation/widgets/add_activity_sheet.dart';
import '../../../calendar/presentation/widgets/calendar_section.dart';
import '../../../achievements/presentation/widgets/achievements_row.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../domain/progress_models.dart';
import '../widgets/plank_card.dart';
import '../widgets/progress_motion.dart';
import '../widgets/streak_overview.dart';

/// Progress tab: streak, activity, calendar, plank trend and skill ladder.
/// Every number comes from history, the active plan and recorded attempts.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final stats = ref.watch(userStatsProvider);
    final history = ref.watch(historyProvider);
    final today = ref.watch(clockProvider)();
    final plank = PlankTrend.from(ref.watch(plankHistoryProvider));
    final bottom = MediaQuery.paddingOf(context).bottom + 24;

    var index = 0;
    Widget card(Widget Function(int i) build) {
      final i = index++;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: CardEntrance(index: i, child: build(i)),
      );
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
          bottom,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 4,
              top: 6,
              bottom: AppSpacing.xl,
            ),
            child: Text(
              'Progress',
              style: AppTypography.title(
                32,
                c.textPrimary,
                weight: FontWeight.w800,
              ),
            ),
          ),
          card(
            (i) => StreakOverview(
              current: stats.currentStreak,
              longest: stats.longestStreak,
              history: history,
              today: today,
              partial: ref.watch(partialLogProvider),
              onBadgeTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AchievementsScreen(),
                ),
              ),
            ),
          ),
          card(
            (i) =>
                AchievementsRow(achievements: ref.watch(achievementsProvider)),
          ),
          card(
            (i) => CalendarSection(
              history: history,
              today: today,
              onAdd: () => showAddActivity(context),
              onDay: (d) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DayActivityScreen(day: d),
                ),
              ),
              onHistory: () => context.push('/history'),
            ),
          ),
          if (plank != null)
            card((i) => PlankCard(trend: plank, delay: innerDelay(i))),
        ],
      ),
    );
  }
}
