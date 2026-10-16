import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/calisthenics_skill.dart';
import '../../../../shared/widgets/glass/app_background.dart';
import '../../../exercises/domain/exercise.dart';
import '../../domain/discover_logic.dart';
import '../providers/discover_providers.dart';
import '../widgets/discover_cards.dart';
import '../widgets/exercise_tile.dart';

/// Full-screen search: pill with an X, keyboard up, and while nothing is
/// typed, chip groups (Skills, Difficulty, Equipment) that start a search in
/// one tap. Results replace the chips as soon as a query or filter is active.
class DiscoverSearchScreen extends ConsumerStatefulWidget {
  const DiscoverSearchScreen({super.key});

  static Route<void> route() => PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => const DiscoverSearchScreen(),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 180),
  );

  @override
  ConsumerState<DiscoverSearchScreen> createState() =>
      _DiscoverSearchScreenState();
}

class _DiscoverSearchScreenState extends ConsumerState<DiscoverSearchScreen> {
  late final TextEditingController _controller;
  late final SearchQueryNotifier _query;
  late final DiscoverFiltersNotifier _filters;

  /// Difficulty chips group the guide's five levels into three.
  static const _levelGroups = {
    'Beginner': {ExerciseLevel.beginner, ExerciseLevel.begInt},
    'Intermediate': {
      ExerciseLevel.begInt,
      ExerciseLevel.intermediate,
      ExerciseLevel.intAdv,
    },
    'Advanced': {ExerciseLevel.intAdv, ExerciseLevel.advanced},
  };

  /// Search words per skill (rung names don't always contain the skill label).
  static const _skillQueries = {
    'dips': 'Dip',
    'pistol-squat': 'Pistol',
    'toes-to-bar': 'Toes',
  };

  @override
  void initState() {
    super.initState();
    _query = ref.read(searchQueryProvider.notifier);
    _filters = ref.read(discoverFiltersProvider.notifier);
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    // Leave Discover in browse mode next time.
    Future.microtask(() {
      _query.set(''); 
      _filters.clear();
    });
    super.dispose();
  }

  bool _groupSelected(Set<ExerciseLevel> group, Set<ExerciseLevel> selected) =>
      selected.containsAll(group);

  void _toggleGroup(Set<ExerciseLevel> group, Set<ExerciseLevel> selected) {
    final remove = _groupSelected(group, selected);
    for (final l in group) {
      if (selected.contains(l) == remove) _filters.toggleLevel(l);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final searching = ref.watch(discoverSearchingProvider);
    final filters = ref.watch(discoverFiltersProvider);
    final results = ref.watch(discoverResultsProvider);

    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: c.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: c.divider.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: c.textSecondary,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              onChanged: (v) {
                                _query.set(v);
                                setState(() {});
                              },
                              style: AppTypography.body(
                                c.textPrimary,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Search',
                                hintStyle: AppTypography.body(
                                  c.textMuted,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _controller.clear();
                                _query.set('');
                                setState(() {});
                              },
                              child: Semantics(
                                button: true,
                                label: 'Clear search',
                                excludeSemantics: true,
                                child: Icon(
                                  Icons.cancel_rounded,
                                  color: c.textPrimary,
                                  size: 24,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    button: true,
                    label: 'Close search',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.surface,
                          border: Border.all(
                            color: c.divider.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: c.textPrimary,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: searching
                  ? _Results(results: results)
                  : ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      children: [
                        const _ChipTitle('Skills'),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final s in calisthenicsSkills)
                              SoftChip(
                                compact: true,
                                label: s.label,
                                onTap: () {
                                  final q = _skillQueries[s.id] ?? s.label;
                                  _controller.text = q;
                                  _query.set(q);
                                },
                              ),
                          ],
                        ),
                        const _ChipTitle('Difficulty'),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final entry in _levelGroups.entries)
                              SoftChip(
                                compact: true,
                                label: entry.key,
                                selected: _groupSelected(
                                  entry.value,
                                  filters.levels,
                                ),
                                onTap: () =>
                                    _toggleGroup(entry.value, filters.levels),
                              ),
                          ],
                        ),
                        const _ChipTitle('Equipment'),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final tag in EquipmentTag.values)
                              SoftChip(
                                compact: true,
                                label: tag.label,
                                selected: filters.equipment.contains(tag),
                                onTap: () => _filters.toggleEquipment(tag),
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipTitle extends StatelessWidget {
  const _ChipTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 14),
    child: Text(
      text,
      style: AppTypography.title(
        22,
        context.appColors.textPrimary,
        weight: FontWeight.w800,
      ),
    ),
  );
}

class _Results extends ConsumerWidget {
  const _Results({required this.results});
  final List<Exercise> results;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final filters = ref.watch(discoverFiltersProvider);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${results.length} ${results.length == 1 ? 'exercise' : 'exercises'}',
                style: AppTypography.body(c.textSecondary, fontSize: 14),
              ),
            ),
            if (filters.isActive)
              TextButton(
                onPressed: () =>
                    ref.read(discoverFiltersProvider.notifier).clear(),
                child: Text(
                  'Clear filters',
                  style: AppTypography.body(
                    c.accentText,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Text(
              'Nothing matches. Try a different word or fewer filters.',
              textAlign: TextAlign.center,
              style: AppTypography.body(c.textSecondary),
            ),
          )
        else
          for (final e in results) ExerciseTile(exercise: e),
      ],
    );
  }
}
