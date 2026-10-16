import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../user/domain/completed_session.dart';
import '../../domain/activity_log.dart';

/// "Calendar — Add Activity", a month you can page through (days she trained
/// are shaded, today is dark), and a Workout History button.
class CalendarSection extends StatefulWidget {
  const CalendarSection({
    super.key,
    required this.history,
    required this.today,
    required this.planned,
    required this.onAdd,
    required this.onDay,
    required this.onHistory,
  });

  final List<CompletedSession> history;
  final DateTime today;

  /// Days of the current month that are planned training days still to come.
  final Set<int> planned;
  final VoidCallback onAdd;
  final ValueChanged<DateTime> onDay;
  final VoidCallback onHistory;

  @override
  State<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<CalendarSection> {
  late DateTime _month = DateTime(widget.today.year, widget.today.month);
  int _dir = 1;

  bool get _atCurrent =>
      _month.year == widget.today.year && _month.month == widget.today.month;

  void _go(int delta) {
    if (delta > 0 && _atCurrent) return;
    setState(() {
      _dir = delta;
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final still = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Calendar',
                  style: AppTypography.title(
                    24,
                    c.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Add Activity',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onAdd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Add Activity',
                      style: AppTypography.title(
                        15,
                        c.accentText,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: GestureDetector(
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v > 200) _go(-1);
              if (v < -200) _go(1);
            },
            child: Column(
              children: [
                Row(
                  children: [
                    _Chevron(
                      icon: Icons.chevron_left_rounded,
                      label: 'Previous month',
                      onTap: () => _go(-1),
                    ),
                    Expanded(
                      child: Text(
                        monthTitle(_month),
                        textAlign: TextAlign.center,
                        style: AppTypography.title(
                          18,
                          c.textPrimary,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                    _Chevron(
                      icon: Icons.chevron_right_rounded,
                      label: 'Next month',
                      onTap: _atCurrent ? null : () => _go(1),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final d in const [
                      'MON',
                      'TUE',
                      'WED',
                      'THU',
                      'FRI',
                      'SAT',
                      'SUN',
                    ])
                      Expanded(
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: AppTypography.body(
                            c.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: still
                      ? Duration.zero
                      : const Duration(milliseconds: 260),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(
                        begin: Offset(0.12 * _dir, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _MonthGrid(
                    key: ValueKey(_month),
                    month: _month,
                    today: widget.today,
                    history: widget.history,
                    planned: _atCurrent ? widget.planned : const {},
                    onDay: widget.onDay,
                  ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  button: true,
                  label: 'Workout History',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: widget.onHistory,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: c.textPrimary, width: 1.3),
                      ),
                      child: Text(
                        'Workout History',
                        style: AppTypography.title(
                          16,
                          c.textPrimary,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 40,
          child: Icon(
            icon,
            size: 28,
            color: onTap == null ? Colors.transparent : c.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    super.key,
    required this.month,
    required this.today,
    required this.history,
    required this.planned,
    required this.onDay,
  });

  final DateTime month;
  final DateTime today;
  final List<CompletedSession> history;
  final Set<int> planned;
  final ValueChanged<DateTime> onDay;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1;
    final trained = {
      for (final s in history)
        if (s.finishedAt.year == month.year &&
            s.finishedAt.month == month.month)
          s.finishedAt.day,
    };
    final t = dayOf(today);
    final rows = ((lead + daysInMonth) / 7).ceil();
    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final day = r * 7 + col - lead + 1;
                      if (day < 1 || day > daysInMonth) {
                        return const SizedBox(height: 50);
                      }
                      final date = DateTime(month.year, month.month, day);
                      final isToday = date == t;
                      final done = trained.contains(day);
                      final future = date.isAfter(t);
                      return Semantics(
                        button: true,
                        label:
                            '${longDate(date)}${done ? ', activity logged' : ''}${isToday ? ', today' : ''}',
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onDay(date),
                          child: SizedBox(
                            height: 50,
                            child: Center(
                              child: Container(
                                width: 42,
                                height: 42,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? c.textPrimary
                                      : done
                                      ? c.surfaceMuted
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$day',
                                      style: AppTypography.body(
                                        isToday
                                            ? c.background
                                            : future
                                            ? c.textMuted
                                            : c.textPrimary,
                                        fontSize: 15,
                                        weight: isToday || done
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    if (planned.contains(day) && !done)
                                      Container(
                                        width: 4,
                                        height: 4,
                                        margin: const EdgeInsets.only(top: 2),
                                        decoration: BoxDecoration(
                                          color: c.accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
