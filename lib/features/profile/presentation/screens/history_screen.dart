import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../calendar/presentation/screens/day_activity_screen.dart';
import '../../../calendar/presentation/widgets/activity_tile.dart';
import '../providers/profile_providers.dart';

/// Workout History: every finished activity, newest first. Tapping one opens
/// that day.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final history = ref.watch(recentHistoryProvider);
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          SizedBox(height: pad.top + 6),
          Row(
            children: [
              Semantics(
                button: true,
                label: 'Back',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                  child: SizedBox(
                    width: 52,
                    height: 48,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Workout History',
                  textAlign: TextAlign.center,
                  style: AppTypography.title(
                    19,
                    c.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 52),
            ],
          ),
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No workouts yet. Finish one and it will show here.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body(c.textMuted, fontSize: 15),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, pad.bottom + 24),
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => ActivityTile(
                      session: history[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              DayActivityScreen(day: history[i].finishedAt),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
