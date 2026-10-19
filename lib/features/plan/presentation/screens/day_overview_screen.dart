import '../../domain/plan_timeline.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../plans/domain/plan_builder.dart';
import '../../../plans/domain/plan_template.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../../workout/domain/workout_request.dart';
import '../../domain/plan_overview.dart';
import '../../../exercises/domain/exercise_lookup.dart';
import '../../../media/data/exercise_videos.dart';
import '../../domain/cover_pictures.dart';
import '../providers/plan_providers.dart';
import '../widgets/day_header.dart';
import '../widgets/day_rows.dart';

/// One planned day: hero header that collapses into a top bar, warm-up /
/// main / cool-down lists with targets, and a fixed START pill.
class DayOverviewScreen extends ConsumerWidget {
  const DayOverviewScreen({super.key, required this.weekday, this.week});

  /// 0 = Monday … 6 = Sunday, within the current week.
  final int weekday;

  /// Plan week (1-based); the current week when null.
  final int? week;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final built = week == null
        ? ref.watch(currentWeekProvider)
        : ref.watch(builtWeekProvider(week!));
    final plan = ref.watch(activePlanProvider);
    final template = ref.watch(activeTemplateProvider);
    final session = (built != null && weekday >= 0 && weekday < 7)
        ? built.days[weekday].session
        : null;

    if (session == null || plan == null) {
      return Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Text(
              'Nothing is planned for this day. Rest up.',
              textAlign: TextAlign.center,
              style: AppTypography.body(c.textSecondary),
            ),
          ),
        ),
      );
    }
    final shownWeek = week ?? plan.weekNumberOn(ref.watch(clockProvider)());
    // Get the first exercises onto the phone while she reads the list, so
    // the workout opens on ready videos.
    for (final n in [
      ...session.warmUp.take(2),
      ...session.items.take(1).map((i) => i.exerciseNumber),
    ]) {
      final e = exerciseByNumber(n);
      ExerciseVideos.save(e, clip: true);
      ExerciseVideos.save(e);
    }
    // The same picture this day wears on the Plan tab.
    final timeline = ref.watch(planTimelineProvider);
    var hero = session.cover;
    // A day that is already done carries no half-way progress: any older
    // percentage saved for it is stale (a finished session ticks off the
    // earliest open day), so it neither shows nor resumes.
    var done = false;
    if (timeline != null) {
      final date = PlanTimeline.dateOf(plan, shownWeek, weekday);
      final days = [for (final ph in timeline.phases) ...ph.days];
      final covers = coverPictures(days);
      for (final d in days) {
        if (d.date == date) {
          hero = covers[d.dayNumber] ?? hero;
          done = d.status == TimelineStatus.done;
        }
      }
    }
    return _Body(
      done: done,
      heroNumber: hero,
      session: session,
      templateId: plan.templateId,
      progressKey: dayProgressKey(
        plan.templateId,
        PlanTimeline.dateOf(plan, shownWeek, weekday),
      ),
      level: _levelLabel(template, plan.stageIndex, plan.profile.level),
    );
  }
}

/// Skill plans show the level of the stage she is on; other plans follow the
/// level she picked, since that is what picks their exercises.
String? _levelLabel(PlanTemplate? t, int stageIndex, PlanLevel chosen) {
  if (t == null || t.stages.isEmpty) return null;
  final s = t.stages[stageIndex.clamp(0, t.stages.length - 1)];
  final level = t.focus == PlanFocus.skill ? s.level : chosen;
  return switch (level) {
    PlanLevel.beginner => 'Beginner',
    PlanLevel.intermediate => 'Intermediate',
    PlanLevel.advanced => 'Advanced',
  };
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.done,
    required this.heroNumber,
    required this.session,
    required this.templateId,
    required this.progressKey,
    required this.level,
  });
  final bool done;
  final int heroNumber;
  final BuiltSession session;
  final String templateId;
  final String progressKey;
  final String? level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final rest = ref.watch(restSecondsProvider);
    final percent = done
        ? null
        : ref.watch(partialProgressProvider)[progressKey];
    final musicOn =
        (ref.watch(settingsProvider)['musicEnabled'] as bool?) ?? true;
    final top = MediaQuery.paddingOf(context).top;
    final animate = !MediaQuery.disableAnimationsOf(context);

    var index = 0;
    List<Widget> section(String title, List<(int, String)> entries) {
      final start = index;
      index += entries.length;
      return [
        SliverToBoxAdapter(
          child: DaySectionHeader(title: title, count: entries.length),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => DayExerciseRow(
              number: entries[i].$1,
              target: entries[i].$2,
              index: start + i,
            ),
            childCount: entries.length,
          ),
        ),
      ];
    }

    const drill = '${PlanBuilder.drillSeconds} s';
    final slivers = <Widget>[
      SliverPersistentHeader(
        pinned: true,
        delegate: DayHeaderDelegate(
          heroNumber: heroNumber,
          topInset: top,
          musicOn: musicOn,
          animate: animate,
          onBack: () => context.pop(),
          onToggleMusic: () =>
              ref.read(settingsProvider.notifier).set('musicEnabled', !musicOn),
        ),
      ),
      SliverToBoxAdapter(
        child: DayTitleBlock(
          title: session.name,
          chips: [
            DayMetaChip(
              icon: Icons.schedule_rounded,
              label: '${session.estimatedMinutes} Mins',
            ),
            if (level != null)
              DayMetaChip(icon: Icons.bolt_rounded, label: level!),
            DayMetaChip(
              icon: Icons.format_list_bulleted_rounded,
              label: '${session.items.length} exercises',
            ),
            if (percent != null)
              DayMetaChip(
                icon: Icons.donut_large_rounded,
                label: '$percent% done',
              ),
            DayMetaChip(
              icon: Icons.timer_outlined,
              label: 'Rest time · $rest s',
              onTap: () => showDayRestSheet(context),
            ),
          ],
        ),
      ),
      ...section('Warm up', [for (final n in session.warmUp) (n, drill)]),
      ...section('Main', [
        for (final i in session.items) (i.exerciseNumber, targetLabel(i)),
      ]),
      ...section('Cool Down', [for (final n in session.coolDown) (n, drill)]),
      const SliverToBoxAdapter(child: SizedBox(height: 120)),
    ];

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          CustomScrollView(slivers: slivers),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DayStartBar(
              resume: percent != null,
              onStart: () => context.push(
                '/workout',
                extra: WorkoutRequest(
                  templateId: templateId,
                  session: session,
                  // A finished day starts from the top and saves no half-way
                  // progress of its own.
                  progressKey: done ? null : progressKey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
