import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/motion/calesthetics_motion.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../workout/domain/workout_request.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../domain/plan_overview.dart';
import '../../domain/cover_pictures.dart';
import '../../domain/plan_timeline.dart';
import '../providers/plan_providers.dart';
import '../../../exercises/presentation/widgets/exercise_thumb.dart';
import '../widgets/day_locked_dialog.dart';
import '../widgets/plan_dropdown.dart';
import '../widgets/plan_sheets.dart';

const _weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Plan tab. The title and plan selector stay pinned; below them the plan's
/// current 4-week block scrolls as phases (one per week) of training days:
/// the next day to train is a hero card, the rest are compact rows.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  /// Whether the "Current Plan" dropdown (all added plans + Add More Plan) is open.
  bool _open = false;

  void _setOpen(bool value) => setState(() => _open = value);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final overview = ref.watch(planOverviewProvider);
    final timeline = ref.watch(planTimelineProvider);
    final bottom = MediaQuery.paddingOf(context).bottom + AppSpacing.xxl;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.xxl,
              0,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Personal Plan',
                        style: AppTypography.title(
                          32,
                          c.textPrimary,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (overview != null)
                      _EditButton(onTap: () => context.push('/plan-settings')),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                if (overview != null)
                  _PlanSelector(
                    overview: overview,
                    open: _open,
                    onTap: () => _setOpen(!_open),
                  ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                children: [
                  ListView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                      bottom,
                    ),
                    children: [
                      if (overview == null || timeline == null)
                        const _EmptyPlan()
                      else ...[
                        if (overview.levelComplete) ...[
                          _LevelUpCard(overview: overview),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        ..._timeline(
                          context,
                          timeline,
                          overview.plan.templateId,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const _OfflineRow(),
                      ],
                    ],
                  ),
                  // Dim the timeline while the dropdown is open; tap to close.
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !_open,
                      child: GestureDetector(
                        onTap: () => _setOpen(false),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _open ? 1 : 0,
                          child: ColoredBox(
                            color: c.cover.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // The dropdown is only built while open; it eases in on open.
                  if (_open)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, -24 * (1 - t)),
                            child: child,
                          ),
                        ),
                        child: PlanDropdownPanel(
                          onClose: () => _setOpen(false),
                          maxHeight: box.maxHeight * 0.92,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _timeline(
    BuildContext context,
    PlanTimeline t,
    String templateId,
  ) {
    final rows = <Widget>[];
    final covers = coverPictures([for (final ph in t.phases) ...ph.days]);
    for (var p = 0; p < t.phases.length; p++) {
      final phase = t.phases[p];
      rows.add(
        _TimelineRow(
          kind: _Node.dot,
          nodeY: 10,
          isFirst: p == 0,
          topGap: p == 0 ? 0 : AppSpacing.xxl,
          child: _PhaseHeader(phase: phase),
        ),
      );
      for (var i = 0; i < phase.days.length; i++) {
        final day = phase.days[i];
        final isHero = identical(day, t.hero);
        final last = p == t.phases.length - 1 && i == phase.days.length - 1;
        rows.add(
          _TimelineRow(
            kind: day.status == TimelineStatus.done ? _Node.done : _Node.ring,
            nodeY: isHero ? 168 : 55,
            isLast: last,
            child: CalestheticsFadeSlide(
              delay: Duration(milliseconds: 30 * i),
              child: isHero
                  ? _HeroDay(
                      day: day,
                      templateId: templateId,
                      cover: covers[day.dayNumber] ?? day.session.cover,
                    )
                  : _CompactDay(
                      day: day,
                      templateId: templateId,
                      cover: covers[day.dayNumber] ?? day.session.cover,
                      // Locked until the day to do now is finished.
                      mustFinishDay: t.isLocked(day) ? t.hero!.dayNumber : null,
                    ),
            ),
          ),
        );
      }
    }
    return rows;
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      label: 'Edit plan',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_rounded, size: 18, color: c.textPrimary),
              const SizedBox(width: 8),
              Text(
                'Edit',
                style: AppTypography.title(
                  16,
                  c.textPrimary,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhaseHeader extends StatelessWidget {
  const _PhaseHeader({required this.phase});
  final TimelinePhase phase;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final range = phase.firstDay == phase.lastDay
        ? 'Day ${phase.firstDay}'
        : 'Day ${phase.firstDay}–${phase.lastDay}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Semantics(
        label:
            'Phase ${phase.index}, $range, ${phase.percent} percent complete',
        excludeSemantics: true,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Phase ${phase.index} ($range)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title(
                  16,
                  c.textMuted,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              width: 72,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: phase.fraction,
                  minHeight: 5,
                  backgroundColor: c.divider,
                  valueColor: AlwaysStoppedAnimation(c.accent),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 46,
              child: Text(
                '${phase.percent}%',
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.end,
                style: AppTypography.body(
                  c.textMuted,
                  fontSize: 15,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlan extends StatelessWidget {
  const _EmptyPlan();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Icon(Icons.event_note_rounded, size: 44, color: c.accentText),
          const SizedBox(height: AppSpacing.lg),
          Text('No plan yet', style: AppTypography.title(20, c.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pick a plan and your first training day appears here.',
            textAlign: TextAlign.center,
            style: AppTypography.body(c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _PrimaryPill(
            label: 'Choose a plan',
            onTap: () => showPlanPicker(context),
          ),
        ],
      ),
    );
  }
}

class _LevelUpCard extends ConsumerWidget {
  const _LevelUpCard({required this.overview});
  final PlanOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    return GlassCard(
      selected: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: c.accentText),
              const SizedBox(width: 8),
              Text('Level 2', style: AppTypography.title(18, c.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'You finished every session of the final block of '
            '${overview.template.name}. Pick your next plan or go around again.',
            style: AppTypography.body(c.textSecondary, fontSize: 13.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _PrimaryPill(
                  label: 'Pick next plan',
                  onTap: () => showPlanPicker(context, title: 'Level 2'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              TextButton(
                onPressed: () =>
                    ref.read(activePlanProvider.notifier).restart(),
                child: Text(
                  'Restart',
                  style: AppTypography.body(
                    c.accentText,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfflineRow extends StatelessWidget {
  const _OfflineRow();

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      label: 'Download plan for offline, not available yet',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_for_offline_rounded,
            size: 18,
            color: c.textMuted,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Download plan for offline · not available yet',
              textAlign: TextAlign.center,
              style: AppTypography.body(c.textMuted, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryPill extends StatelessWidget {
  const _PrimaryPill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.accent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: AppTypography.title(15, c.onAccent, weight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _PlanSelector extends StatelessWidget {
  const _PlanSelector({
    required this.overview,
    required this.open,
    required this.onTap,
  });
  final PlanOverview overview;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      label:
          'Current plan ${overview.template.name}. ${open ? 'Close' : 'Show all plans'}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 76,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.accent, width: 1.6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Plan',
                        style: AppTypography.title(
                          20,
                          c.textPrimary,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        overview.template.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          c.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 76,
                color: c.accent,
                alignment: Alignment.center,
                child: AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: c.onAccent,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpinePainter extends CustomPainter {
  _SpinePainter({
    required this.kind,
    required this.isFirst,
    required this.isLast,
    required this.nodeY,
    required this.line,
    required this.accent,
    required this.surface,
    required this.muted,
    required this.onAccent,
  });
  final _Node kind;
  final bool isFirst;
  final bool isLast;
  final double nodeY;
  final Color line, accent, surface, muted, onAccent;

  @override
  void paint(Canvas canvas, Size size) {
    const x = 9.0;
    final paint = Paint()
      ..color = line
      ..strokeWidth = 1.6;
    var y = isFirst ? nodeY : 0.0;
    final end = isLast ? nodeY : size.height;
    while (y < end) {
      canvas.drawLine(Offset(x, y), Offset(x, math.min(y + 5, end)), paint);
      y += 10;
    }
    final center = Offset(x, math.min(nodeY, size.height - 8));
    switch (kind) {
      case _Node.dot:
        canvas.drawCircle(center, 5, Paint()..color = muted);
      case _Node.rest:
        canvas.drawCircle(center, 4, Paint()..color = line);
      case _Node.ring:
        canvas.drawCircle(center, 10, Paint()..color = surface);
        canvas.drawCircle(
          center,
          10,
          Paint()
            ..color = line
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      case _Node.today:
        canvas.drawCircle(center, 10, Paint()..color = surface);
        canvas.drawCircle(
          center,
          10,
          Paint()
            ..color = accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );
        canvas.drawCircle(center, 4, Paint()..color = accent);
      case _Node.done:
        canvas.drawCircle(center, 10, Paint()..color = accent);
        final tick = Path()
          ..moveTo(center.dx - 4.5, center.dy)
          ..lineTo(center.dx - 1, center.dy + 3.5)
          ..lineTo(center.dx + 5, center.dy - 3.5);
        canvas.drawPath(
          tick,
          Paint()
            ..color = onAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
    }
  }

  @override
  bool shouldRepaint(_SpinePainter old) =>
      old.kind != kind ||
      old.nodeY != nodeY ||
      old.line != line ||
      old.accent != accent ||
      old.surface != surface;
}

enum _Node { dot, ring, today, done, rest }

/// One timeline entry: a dashed spine with a node on the left, content on the right.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.kind,
    required this.child,
    required this.nodeY,
    this.isFirst = false,
    this.isLast = false,
    this.topGap = 0,
  });
  final _Node kind;
  final Widget child;
  final double nodeY;
  final bool isFirst;
  final bool isLast;
  final double topGap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: CustomPaint(
                painter: _SpinePainter(
                  kind: kind,
                  isFirst: isFirst,
                  isLast: isLast,
                  nodeY: nodeY,
                  line: c.divider,
                  accent: c.accent,
                  surface: c.surface,
                  muted: c.textMuted,
                  onAccent: c.onAccent,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: kind == _Node.dot ? 0 : AppSpacing.lg,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The next training day: big image card with title overlay and Start Training.
class _HeroDay extends ConsumerWidget {
  const _HeroDay({
    required this.day,
    required this.templateId,
    required this.cover,
  });
  final TimelineDay day;
  final String templateId;

  /// Catalog number of the exercise whose picture heads the card.
  final int cover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percent = ref.watch(
      partialProgressProvider,
    )[dayProgressKey(templateId, day.date)];
    final c = context.appColors;
    final session = day.session;
    final subtitle =
        '${session.estimatedMinutes} Mins · ${session.items.length} exercises';
    final dateLabel = '${_weekdayShort[day.date.weekday - 1]}.${day.date.day}';
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () =>
                context.push('/day/${day.weekday}?week=${day.weekNumber}'),
            child: SizedBox(
              height: 190,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ExerciseThumb(number: cover, size: 400, radiusFactor: 0),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [c.scrim(0), c.scrim(0.7)],
                          stops: const [0.35, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            session.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.title(
                              24,
                              Colors.white,
                              weight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: AppTypography.body(
                              Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Day ${day.dayNumber}',
                  style: AppTypography.title(
                    30,
                    c.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  dateLabel,
                  style: AppTypography.body(c.textSecondary, fontSize: 16),
                ),
                if (percent != null) ...[
                  const Spacer(),
                  Text(
                    '$percent% done',
                    style: AppTypography.body(
                      c.accentText,
                      fontSize: 15,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _PrimaryPill(
            label: percent != null ? 'Resume Training' : 'Start Training',
            onTap: () => context.push(
              '/workout',
              extra: WorkoutRequest(
                templateId: templateId,
                session: session,
                progressKey: dayProgressKey(templateId, day.date),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Any other training day: thumbnail, "Day N", minutes and exercise count.
class _CompactDay extends ConsumerWidget {
  const _CompactDay({
    required this.day,
    required this.templateId,
    required this.cover,
    this.mustFinishDay,
  });
  final TimelineDay day;
  final String templateId;

  /// The day that has to be finished before this one opens, or null when
  /// this day is open.
  final int? mustFinishDay;

  /// Catalog number of the exercise whose picture heads the card.
  final int cover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final percent = ref.watch(
      partialProgressProvider,
    )[dayProgressKey(templateId, day.date)];
    final session = day.session;
    final done = day.status == TimelineStatus.done;
    return GlassCard(
      padding: const EdgeInsets.all(10),
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        final first = mustFinishDay;
        if (first != null) {
          showDayLockedDialog(
            context,
            finishDay: first,
            tappedDay: day.dayNumber,
          );
          return;
        }
        context.push('/day/${day.weekday}?week=${day.weekNumber}');
      },
      child: Row(
        children: [
          ExerciseThumb(number: cover, size: 90, radiusFactor: 0.16),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day ${day.dayNumber}',
                  style: AppTypography.title(
                    24,
                    c.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.estimatedMinutes} Mins · ${session.items.length} exercises',
                  style: AppTypography.body(c.textSecondary, fontSize: 14.5),
                ),
                if (!done && percent != null)
                  Text(
                    '$percent% done',
                    style: AppTypography.body(
                      c.accentText,
                      fontSize: 13,
                      weight: FontWeight.w700,
                    ),
                  ),
                if (done)
                  Text(
                    'Done',
                    style: AppTypography.body(
                      c.success,
                      fontSize: 13,
                      weight: FontWeight.w700,
                    ),
                  )
                else
                  Text(
                    '${_weekdayShort[day.date.weekday - 1]}.${day.date.day} · ${session.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(c.textMuted, fontSize: 12.5),
                  ),
              ],
            ),
          ),
          Icon(
            mustFinishDay != null
                ? Icons.lock_outline_rounded
                : Icons.chevron_right_rounded,
            color: c.textSecondary,
          ),
        ],
      ),
    );
  }
}
