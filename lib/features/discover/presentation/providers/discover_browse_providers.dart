import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../exercises/domain/exercise.dart';
import '../../../exercises/domain/exercise_lookup.dart';
import '../../../user/presentation/providers/user_providers.dart';

/// The chip row at the top of Discover. `all` browses everything; the rest
/// narrow the page to one group.
enum DiscoverCategory {
  all('All'),
  favorites('Favorites'),
  skills('Skills'),
  upper('Upper body'),
  core('Core'),
  legs('Legs & glutes'),
  conditioning('Conditioning'),
  mobility('Mobility');

  const DiscoverCategory(this.label);
  final String label;

  /// Catalog section behind a foundation/mobility category, if any.
  String? get sectionId => switch (this) {
    upper => 'foundation-upper',
    core => 'foundation-core',
    legs => 'foundation-legs',
    conditioning => 'foundation-conditioning',
    mobility => 'warmup-mobility',
    _ => null,
  };
}

class DiscoverCategoryNotifier extends Notifier<DiscoverCategory> {
  @override
  DiscoverCategory build() => DiscoverCategory.all;
  void select(DiscoverCategory c) => state = c;
}

final discoverCategoryProvider =
    NotifierProvider<DiscoverCategoryNotifier, DiscoverCategory>(
      DiscoverCategoryNotifier.new,
    );

/// "Top picks": the exercises of the session she should do next, so the
/// row always reflects her real plan. Without a plan: a few beginner-friendly
/// exercises from the foundation sections.
final topPicksProvider = Provider<List<Exercise>>((ref) {
  final week = ref.watch(currentWeekProvider);
  if (week != null) {
    final next = [
      for (final d in week.days)
        if (d.session != null) d.session!,
    ].firstOrNull;
    if (next != null) {
      final seen = <int>{};
      return [
        for (final item in next.items)
          if (seen.add(exerciseByNumber(item.exerciseNumber).videoNumber))
            exerciseByNumber(item.exerciseNumber),
      ];
    }
  }
  return [
    for (final id in const [
      'foundation-upper',
      'foundation-core',
      'foundation-legs',
    ])
      ...exercisesInSection(id)
          .where((e) => !e.sharesVideo && e.level == ExerciseLevel.beginner)
          .take(2),
  ];
});
