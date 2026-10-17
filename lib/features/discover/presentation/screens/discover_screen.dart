import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/motion/calesthetics_motion.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/calisthenics_skill.dart';
import '../../../../shared/widgets/glass/app_background.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../exercises/data/exercise_catalog.dart';
import '../../../exercises/domain/exercise.dart';
import '../../../exercises/domain/exercise_lookup.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../domain/discover_logic.dart';
import '../providers/discover_browse_providers.dart';
import '../providers/discover_providers.dart';
import '../widgets/discover_cards.dart';
import '../widgets/exercise_tile.dart';
import 'discover_search_screen.dart';
import 'exercise_list_screen.dart';
import 'media_debug_screen.dart';

const _areas = [
  ('foundation-upper', 'Upper body', 'Foundation: Upper body'),
  ('foundation-core', 'Core', 'Foundation: Core'),
  ('foundation-legs', 'Legs', 'Foundation: Legs & glutes'),
  ('foundation-conditioning', 'Conditioning', 'Foundation: Conditioning'),
  ('warmup-mobility', 'Mobility', 'Warm-up & Mobility'),
];

const _categoryIcons = {
  DiscoverCategory.all: Icons.grid_view_rounded,
  DiscoverCategory.favorites: Icons.favorite_border_rounded,
  DiscoverCategory.skills: Icons.stairs_rounded,
  DiscoverCategory.upper: Icons.accessibility_new_rounded,
  DiscoverCategory.core: Icons.self_improvement_rounded,
  DiscoverCategory.legs: Icons.directions_run_rounded,
  DiscoverCategory.conditioning: Icons.bolt_rounded,
  DiscoverCategory.mobility: Icons.spa_rounded,
};

/// Discover tab. Big title that collapses into a pinned centered one, a
/// search pill that opens full-screen search, category chips, and sections
/// each with its own presentation: photo cards, gradient ladder cards,
/// round area bubbles and equipment chips.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _scroll = ScrollController();
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final collapsed = _scroll.hasClients && _scroll.offset > 52;
      if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openSection(String title, List<Exercise> exercises) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SectionScreen(title: title, exercises: exercises),
      ),
    );
  }

  void _openLadder(String skillId) {
    final skill = calisthenicsSkills.firstWhere((s) => s.id == skillId);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            LadderScreen(skillId: skillId, title: '${skill.label} ladder'),
      ),
    );
  }

  void _openAllLadders() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const LaddersScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final category = ref.watch(discoverCategoryProvider);
    final bottom = MediaQuery.paddingOf(context).bottom + 24;

    return GradientScaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: 44,
              automaticallyImplyLeading: false,
              backgroundColor: c.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: _collapsed ? 1 : 0,
                child: Text(
                  'Discover',
                  style: AppTypography.title(
                    18,
                    c.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPress: kDebugMode
                          ? () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const MediaDebugScreen(),
                              ),
                            )
                          : null,
                      child: Text(
                        'Discover',
                        style: AppTypography.title(
                          32,
                          c.textPrimary,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SearchPill(
                      onTap: () =>
                          Navigator.of(context)
                              .push(DiscoverSearchScreen.route()),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: DiscoverCategory.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final cat = DiscoverCategory.values[i];
                    return SoftChip(
                      label: cat.label,
                      icon: _categoryIcons[cat],
                      selected: cat == category,
                      onTap: () => ref
                          .read(discoverCategoryProvider.notifier)
                          .select(cat),
                    );
                  },
                ),
              ),
            ),
            ..._content(category),
            SliverToBoxAdapter(child: SizedBox(height: bottom)),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(DiscoverCategory category) {
    switch (category) {
      case DiscoverCategory.all:
        return _browseAll();
      case DiscoverCategory.skills:
        return [
          SliverToBoxAdapter(
            child: const SectionHeader(title: 'Skill ladders'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: calisthenicsSkills.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, i) => SizedBox(
                height: 190,
                child: _ladderCard(
                  calisthenicsSkills[i],
                  width: double.infinity,
                ),
              ),
            ),
          ),
        ];
      case DiscoverCategory.favorites:
        final favorites = ref.watch(favoritesProvider);
        final list = [
          for (final e in exerciseCatalog)
            if (favorites.contains(e.number)) e,
        ];
        return [
          const SliverToBoxAdapter(child: SectionHeader(title: 'Favorites')),
          if (list.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Tap the heart on any exercise to keep it here.',
                  style: AppTypography.body(context.appColors.textSecondary),
                ),
              ),
            )
          else
            _tiles(list),
        ];
      default:
        final id = category.sectionId!;
        return [
          SliverToBoxAdapter(child: SectionHeader(title: category.label)),
          _tiles([
            for (final e in exercisesInSection(id))
              if (!e.sharesVideo) e,
          ]),
        ];
    }
  }

  SliverPadding _tiles(List<Exercise> list) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    sliver: SliverList.builder(
      itemCount: list.length,
      itemBuilder: (_, i) => ExerciseTile(exercise: list[i]),
    ),
  );

  Widget _ladderCard(CalisthenicsSkill skill, {double width = 290}) {
    final rung = ref.watch(currentRungProvider(skill.id));
    final ladder = ladderFor(skill.id);
    final index = ladder.indexWhere((r) => r.number == rung.number) + 1;
    final started =
        ref.watch(continueLadderSkillProvider) == skill.id || index > 1;
    return GradientProgramCard(
      width: width,
      imageKey: 'thumbnails/ladder_${skill.id}',
      colors: skillGradients[skill.id]!,
      kicker: '${ladder.length} RUNGS',
      title: skill.label,
      blurb: 'Your rung: ${rung.name}',
      buttonLabel: started ? 'CONTINUE' : 'START',
      onTap: () => _openLadder(skill.id),
    );
  }

  List<Widget> _browseAll() {
    final picks = ref.watch(topPicksProvider);
    final continueSkill = ref.watch(continueLadderSkillProvider);
    final plan = ref.watch(activeTemplateProvider);
    final favorites = ref.watch(favoritesProvider);

    Widget strip(double height, List<Widget> children) => SliverToBoxAdapter(
      child: HorizontalStrip(height: height, children: children),
    );

    return [
      if (picks.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: SectionHeader(
            title: plan != null ? 'Top Picks' : 'Start here',
            onSeeAll: () =>
                _openSection(plan != null ? 'Top Picks' : 'Start here', picks),
          ),
        ),
        strip(250 * (1 / 1.55) + 44, [
          for (final e in picks)
            ExercisePhotoCard(
              exercise: e,
              onTap: () => context.push('/exercise/${e.number}'),
            ),
        ]),
      ],
      if (continueSkill != null) ...[
        const SliverToBoxAdapter(
          child: SectionHeader(title: 'Continue your ladder'),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: CalestheticsFadeSlide(
              child: SizedBox(
                height: 190,
                child: _ladderCard(
                  calisthenicsSkills.firstWhere((s) => s.id == continueSkill),
                  width: double.infinity,
                ),
              ),
            ),
          ),
        ),
      ],
      SliverToBoxAdapter(
        child: SectionHeader(title: 'Skill ladders', onSeeAll: _openAllLadders),
      ),
      strip(190, [for (final s in calisthenicsSkills) _ladderCard(s)]),
      const SliverToBoxAdapter(child: SectionHeader(title: 'Target Area')),
      strip(92, [
        for (final (id, label, screenTitle) in _areas)
          AreaBubble(
            label: label,
            imageKey: 'thumbnails/area_$id',
            colors: areaGradients[id]!,
            onTap: () => _openSection(screenTitle, exercisesInSection(id)),
          ),
      ]),
      for (final (id, label, screenTitle) in _areas.take(4)) ...[
        SliverToBoxAdapter(
          child: SectionHeader(
            title: label == 'Legs' ? 'Legs & glutes' : label,
            onSeeAll: () => _openSection(screenTitle, exercisesInSection(id)),
          ),
        ),
        strip(250 * (1 / 1.55) + 44, [
          for (final e in exercisesInSection(
            id,
          ).where((e) => !e.sharesVideo).take(8))
            ExercisePhotoCard(
              exercise: e,
              onTap: () => context.push('/exercise/${e.number}'),
            ),
        ]),
      ],
      const SliverToBoxAdapter(child: SectionHeader(title: 'Equipment')),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final tag in EquipmentTag.values)
                SoftChip(
                  compact: true,
                  label: tag.label,
                  onTap: () {
                    ref.read(discoverFiltersProvider.notifier)
                      ..clear()
                      ..toggleEquipment(tag);
                    Navigator.of(context).push(DiscoverSearchScreen.route());
                  },
                ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SectionHeader(
          title: 'Warm-up & Mobility',
          onSeeAll: () => _openSection(
            'Warm-up & Mobility',
            exercisesInSection('warmup-mobility'),
          ),
        ),
      ),
      strip(250 * (1 / 1.55) + 44, [
        for (final e in exercisesInSection(
          'warmup-mobility',
        ).where((e) => !e.sharesVideo).take(8))
          ExercisePhotoCard(
            exercise: e,
            onTap: () => context.push('/exercise/${e.number}'),
          ),
      ]),
      if (favorites.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Your favorites',
            onSeeAll: () => _openSection('Favorites', [
              for (final e in exerciseCatalog)
                if (favorites.contains(e.number)) e,
            ]),
          ),
        ),
        strip(250 * (1 / 1.55) + 44, [
          for (final n in favorites.take(8))
            ExercisePhotoCard(
              exercise: exerciseByNumber(n),
              onTap: () => context.push('/exercise/$n'),
            ),
        ]),
      ],
    ];
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      label: 'Search exercises',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: c.divider.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: c.textSecondary, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search exercises, skills or equipment',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(c.textMuted, fontSize: 15.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
