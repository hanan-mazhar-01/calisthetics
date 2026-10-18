import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/motion/calesthetics_motion.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../plans/data/plan_templates.dart';
import '../providers/plan_providers.dart';
import '../widgets/plan_showcase_card.dart';

/// "Add More Plan" opens this: the plans the user follows ("My Plan") and
/// every other plan ("Other Plan") as colourful cards. A card opens the
/// plan's details, where it can be joined.
class AllPlansScreen extends ConsumerWidget {
  const AllPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final mine = ref.watch(planCardsProvider);
    final ordered = [
      ...mine.where((m) => m.isCurrent),
      ...mine.where((m) => !m.isCurrent),
    ];
    final ownedIds = {for (final m in mine) m.template.id};
    final others = [
      for (final t in planTemplates)
        if (!ownedIds.contains(t.id)) t,
    ];

    final items = <Widget>[
      if (ordered.isNotEmpty) _Heading('My Plan', top: 4),
      for (final m in ordered)
        _Spaced(
          PlanShowcaseCard(
            template: m.template,
            isCurrent: m.isCurrent,
            progress: PlanProgressInfo(
              doneDays: m.doneDays,
              totalDays: m.totalDays,
              phaseDone: m.phaseDone,
            ),
            onTap: () => context.push('/plans/${m.template.id}'),
          ),
        ),
      if (others.isNotEmpty)
        _Heading('Other Plan', top: ordered.isEmpty ? 4 : 14),
      for (final t in others)
        _Spaced(
          PlanShowcaseCard(
            template: t,
            onTap: () => context.push('/plans/${t.id}'),
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const PlanTopBar(title: 'All Plan'),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  MediaQuery.paddingOf(context).bottom + 24,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) => i < 8
                    ? CalestheticsFadeSlide(
                        delay: Duration(milliseconds: 40 * i),
                        offset: 14,
                        child: items[i],
                      )
                    : items[i],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Back arrow and a centred title, as on both plan pages.
class PlanTopBar extends StatelessWidget {
  const PlanTopBar({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Back',
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: c.textPrimary,
              ),
            ),
          ),
          Text(
            title,
            style: AppTypography.title(
              18,
              c.textPrimary,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.top = 0});
  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top, bottom: 12),
    child: Text(
      text,
      style: AppTypography.title(
        18,
        context.appColors.textPrimary,
        weight: FontWeight.w700,
      ),
    ),
  );
}

class _Spaced extends StatelessWidget {
  const _Spaced(this.child);
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 16), child: child);
}
