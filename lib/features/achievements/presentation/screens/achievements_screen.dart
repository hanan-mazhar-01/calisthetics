import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../onboarding/presentation/providers/onboarding_controller.dart';
import '../../../profile/domain/achievement_evaluator.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../widgets/achievement_decor.dart';
import '../widgets/achievement_text.dart';
import '../widgets/medal_badge.dart';
import 'achievement_celebration_screen.dart';

/// Opens a medal's celebration when it is earned.
void openMedal(BuildContext context, Achievement a) {
  if (!a.unlocked) return;
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, _, _) => AchievementCelebrationScreen(achievement: a),
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    ),
  );
}

/// The whole medal collection: a pink header that shrinks as you scroll,
/// tabs per kind of medal, and a grid of hexagon medals.
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key, this.initialId});
  final String? initialId;

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  AchievementCategory _tab = AchievementCategory.streak;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialId;
    if (_selectedId != null) {
      final a = ref
          .read(achievementsProvider)
          .where((x) => x.id == _selectedId)
          .firstOrNull;
      if (a != null) _tab = a.category;
    }
  }

  Achievement _featured(List<Achievement> all) {
    final picked = all.where((a) => a.id == _selectedId).firstOrNull;
    if (picked != null) return picked;
    final earned = all.where((a) => a.unlocked && a.unlockedAt != null).toList()
      ..sort((x, y) => y.unlockedAt!.compareTo(x.unlockedAt!));
    return earned.firstOrNull ?? all.first;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final all = ref.watch(achievementsProvider);
    final name = ref
        .watch(onboardingControllerProvider.select((s) => s.name))
        .trim();
    final featured = _featured(all);
    final shown = all.where((a) => a.category == _tab).toList();
    final earnedCount = all.where((a) => a.unlocked).length;
    final pad = MediaQuery.paddingOf(context);
    final maxH = pad.top + 470;
    final minH = pad.top + 270;

    return Scaffold(
      backgroundColor: c.background,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _HeaderDelegate(
              minExtent: minH,
              maxExtent: maxH,
              topInset: pad.top,
              name: name.isEmpty
                  ? 'there'
                  : name[0].toUpperCase() + name.substring(1),
              earnedCount: earnedCount,
              featured: featured,
              all: all,
              onBack: () => Navigator.of(context).pop(),
              onOpen: () => openMedal(context, featured),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabsDelegate(
              selected: _tab,
              onSelect: (t) => setState(() => _tab = t),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, pad.bottom + 40),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 8,
                mainAxisExtent: 188,
              ),
              itemCount: shown.length,
              itemBuilder: (context, i) {
                final a = shown[i];
                return _MedalCell(
                  achievement: a,
                  selected: a.id == featured.id,
                  onTap: () {
                    if (a.id == featured.id) {
                      openMedal(context, a);
                    } else {
                      setState(() => _selectedId = a.id);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MedalCell extends StatelessWidget {
  const _MedalCell({
    required this.achievement,
    required this.selected,
    required this.onTap,
  });
  final Achievement achievement;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final a = achievement;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${a.title}, ${a.unlocked ? 'earned' : 'locked, ${a.current} of ${a.target}'}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected
                ? c.softRose.withValues(alpha: 0.7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
          child: Column(
            children: [
              MedalBadge(
                number: a.number,
                unit: a.unit,
                earned: a.unlocked,
                size: 92,
              ),
              const SizedBox(height: 6),
              Text(
                a.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(
                  a.unlocked ? c.textPrimary : c.textMuted,
                  fontSize: 13.5,
                  weight: a.unlocked ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (a.unlocked && a.unlockedAt != null)
                Text(
                  medalDate(a.unlockedAt!),
                  style: AppTypography.body(c.textMuted, fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  _TabsDelegate({required this.selected, required this.onSelect});
  final AchievementCategory selected;
  final ValueChanged<AchievementCategory> onSelect;

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final c = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          for (final t in AchievementCategory.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: t == selected,
                label: t.label,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(t),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.label,
                        style: AppTypography.body(
                          t == selected ? c.textPrimary : c.textMuted,
                          fontSize: 14,
                          weight: t == selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ).copyWith(letterSpacing: 0.4),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: t == selected ? 26 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: c.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabsDelegate old) => old.selected != selected;
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.topInset,
    required this.name,
    required this.earnedCount,
    required this.featured,
    required this.all,
    required this.onBack,
    required this.onOpen,
  });

  @override
  final double minExtent;
  @override
  final double maxExtent;
  final double topInset;
  final String name;
  final int earnedCount;
  final Achievement featured;
  final List<Achievement> all;
  final VoidCallback onBack;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final c = context.appColors;
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final big = (1 - t * 1.7).clamp(0.0, 1.0);
    final small = ((t - 0.35) / 0.65).clamp(0.0, 1.0);
    final earned = all.where((a) => a.unlocked).toList();
    final decor = [for (final a in earned.reversed.take(3)) a];
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.softRose, c.background],
            ),
          ),
        ),
        // Expanded: greeting, floating medals, ribbon.
        Opacity(
          opacity: big,
          child: Stack(
            children: [
              Positioned(
                left: 22,
                top: topInset + 78,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, $name',
                      style: AppTypography.title(
                        26,
                        c.textPrimary,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: 'Received ',
                        children: [
                          TextSpan(
                            text: '$earnedCount',
                            style: AppTypography.title(
                              18,
                              c.accentText,
                              weight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: earnedCount == 1 ? ' medal' : ' medals',
                          ),
                        ],
                      ),
                      style: AppTypography.body(c.textSecondary, fontSize: 15),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 22,
                top: topInset + 52,
                child: SizedBox(
                  width: 150,
                  height: 130,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: 8,
                        top: 6,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          child: Center(
                            child: MedalBadge(
                              number: featured.number,
                              unit: featured.unit,
                              earned: featured.unlocked,
                              size: 78,
                            ),
                          ),
                        ),
                      ),
                      for (var i = 0; i < decor.length; i++)
                        Positioned(
                          left: [0.0, 14.0, 102.0][i],
                          top: [18.0, 84.0, 96.0][i],
                          child: Transform.rotate(
                            angle: [-0.25, 0.2, 0.35][i],
                            child: MedalBadge(
                              number: decor[i].number,
                              unit: '',
                              earned: true,
                              size: 36,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: topInset + 168,
                left: 0,
                right: 0,
                child: const Center(child: RibbonBanner(text: 'Achievements')),
              ),
            ],
          ),
        ),
        // Featured medal: big while expanded, smaller once the header shrinks.
        Positioned(
          left: 0,
          right: 0,
          bottom: 14,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onOpen,
                child: SizedBox(
                  width: 250,
                  height: math.max(96, 190 * (1 - t) + 96 * t),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: big,
                        child: const LaurelWreath(size: 250),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: MedalBadge(
                          key: ValueKey(featured.id),
                          number: featured.number,
                          unit: featured.unit,
                          earned: featured.unlocked,
                          size: 150 * (1 - t) + 92 * t,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                featured.title,
                style: AppTypography.title(
                  18,
                  c.textPrimary,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                featured.unlocked && featured.unlockedAt != null
                    ? medalDate(featured.unlockedAt!)
                    : '${featured.current} / ${featured.target} · ${featured.description}',
                textAlign: TextAlign.center,
                style: AppTypography.body(c.textMuted, fontSize: 12.5),
              ),
            ],
          ),
        ),
        // Top bar.
        Positioned(
          left: 4,
          right: 4,
          top: topInset + 6,
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'Back',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBack,
                  child: SizedBox(
                    width: 48,
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
                child: Opacity(
                  opacity: small,
                  child: Text(
                    'Achievement',
                    textAlign: TextAlign.center,
                    style: AppTypography.title(
                      18,
                      c.textPrimary,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(_HeaderDelegate old) => true;
}
