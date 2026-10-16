import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../user/domain/completed_session.dart';
import '../../../user/domain/partial_effort.dart';
import 'progress_motion.dart';

/// Which slice of history the totals card shows.
enum StreakRange {
  all('All'),
  month('Month'),
  week('Week');

  const StreakRange(this.label);
  final String label;
}

/// Totals for one [StreakRange]. Everything comes from finished workouts.
class RangeTotals {
  const RangeTotals({
    required this.workouts,
    required this.minutes,
    required this.exercises,
  });

  final int workouts;
  final int minutes;
  final int exercises;

  factory RangeTotals.of(
    List<CompletedSession> history,
    StreakRange range,
    DateTime today, {
    List<PartialEffort> partial = const [],
  }) {
    final day = DateTime(today.year, today.month, today.day);
    final monday = day.subtract(Duration(days: day.weekday - 1));
    bool inRange(CompletedSession s) {
      final d = DateTime(
        s.finishedAt.year,
        s.finishedAt.month,
        s.finishedAt.day,
      );
      return switch (range) {
        StreakRange.all => true,
        StreakRange.month => d.year == day.year && d.month == day.month,
        StreakRange.week =>
          !d.isBefore(monday) &&
              d.isBefore(monday.add(const Duration(days: 7))),
      };
    }

    bool partialInRange(PartialEffort e) => inRange(
      CompletedSession(
        finishedAt: e.at,
        templateId: '',
        sessionName: '',
        durationSeconds: 0,
        exerciseNumbers: const [],
      ),
    );

    final picked = history.where(inRange).toList();
    final early = partial.where(partialInRange).toList();
    final seconds =
        picked.fold<int>(0, (a, s) => a + s.durationSeconds) +
        early.fold<int>(0, (a, e) => a + e.seconds);
    return RangeTotals(
      // Only finished workouts count as workouts; early exits add time only.
      workouts: picked.length,
      minutes: (seconds / 60).round(),
      exercises:
          picked.fold<int>(0, (a, s) => a + s.exerciseNumbers.length) +
          early.fold<int>(0, (a, e) => a + e.exercises),
    );
  }
}

/// "Streak": a badge with active days / longest / current, and a tabbed card
/// with workouts / minutes / exercises for All, Month or Week.
class StreakOverview extends StatefulWidget {
  const StreakOverview({
    super.key,
    required this.current,
    required this.longest,
    required this.history,
    required this.today,
    this.partial = const [],
    this.onBadgeTap,
  });

  final int current;
  final int longest;
  final List<CompletedSession> history;
  final DateTime today;
  final List<PartialEffort> partial;
  final VoidCallback? onBadgeTap;

  @override
  State<StreakOverview> createState() => _StreakOverviewState();
}

class _StreakOverviewState extends State<StreakOverview> {
  StreakRange _range = StreakRange.all;

  int get _activeDays => {
    for (final s in widget.history)
      DateTime(s.finishedAt.year, s.finishedAt.month, s.finishedAt.day),
  }.length;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final totals = RangeTotals.of(
      widget.history,
      _range,
      widget.today,
      partial: widget.partial,
    );
    final still = reduceMotion(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            'Streak',
            style: AppTypography.title(
              28,
              c.textPrimary,
              weight: FontWeight.w800,
            ),
          ),
        ),
        // Card 1: badge and streak numbers.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 22, 12, 26),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Semantics(
                button: widget.onBadgeTap != null,
                label: 'Streak badge. Opens your achievements',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: widget.onBadgeTap,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: still ? 1 : 0.7, end: 1),
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutBack,
                    builder: (context, t, child) => Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Transform.scale(scale: t, child: child),
                    ),
                    child: Image.asset(
                      'assets/images/streak_badge.png',
                      width: 96,
                      height: 96,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              _StatRow(
                items: [
                  _Stat('Active days', _activeDays),
                  _Stat('Longest', widget.longest),
                  _Stat('Current', widget.current),
                ],
                dividers: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Card 2: All / Month / Week tabs over the totals.
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Row(
                children: [
                  for (final r in StreakRange.values)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: r == _range,
                        label: r.label,
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _range = r),
                          child: AnimatedContainer(
                            duration: still
                                ? Duration.zero
                                : const Duration(milliseconds: 220),
                            height: 56,
                            alignment: Alignment.center,
                            color: r == _range ? c.surface : c.surfaceMuted,
                            child: AnimatedDefaultTextStyle(
                              duration: still
                                  ? Duration.zero
                                  : const Duration(milliseconds: 220),
                              style: AppTypography.body(
                                r == _range ? c.textPrimary : c.textMuted,
                                fontSize: 17,
                                weight: r == _range
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                              child: Text(r.label),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Container(
                width: double.infinity,
                color: c.surface,
                padding: const EdgeInsets.fromLTRB(12, 28, 12, 28),
                child: _StatRow(
                  key: ValueKey(_range),
                  items: [
                    _Stat('Workouts', totals.workouts),
                    _Stat('Minutes', totals.minutes),
                    _Stat('Exercises', totals.exercises),
                  ],
                  dividers: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value);
  final String label;
  final int value;
}

/// Three evenly spaced "number over label" columns, optionally divided by
/// thin vertical lines. Numbers count up when they appear or change.
class _StatRow extends StatelessWidget {
  const _StatRow({super.key, required this.items, required this.dividers});

  final List<_Stat> items;
  final bool dividers;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final still = reduceMotion(context);
    return IntrinsicHeight(
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (dividers && i > 0)
              VerticalDivider(
                width: 1,
                thickness: 1,
                indent: 4,
                endIndent: 4,
                color: c.divider,
              ),
            Expanded(
              child: Semantics(
                label: '${items[i].label}: ${items[i].value}',
                excludeSemantics: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: still ? 1 : 0, end: 1),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, _) => Text(
                        '${(items[i].value * t).round()}',
                        style:
                            AppTypography.title(
                              34,
                              c.textPrimary,
                              weight: FontWeight.w800,
                            ).copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      items[i].label,
                      textAlign: TextAlign.center,
                      style: AppTypography.body(c.textMuted, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
