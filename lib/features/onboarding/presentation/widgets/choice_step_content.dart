import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/onboarding_step.dart';
import 'onboarding_viewport.dart';
import '../providers/onboarding_controller.dart';
import 'choice_grid_tile.dart';
import 'choice_list_tile.dart';
import 'level_slider_content.dart';
import 'typewriter_text.dart';

/// Renders a [ChoiceStep] as either a vertical list or a photo grid, wiring
/// taps to [OnboardingController.toggleOption] and auto-advancing single-select
/// steps after a short delay so the selection animation is visible first.
/// Lets the same cards edit something other than the onboarding answers
/// (e.g. the plan settings draft): the screen supplies the current selection
/// and receives taps; nothing is written to onboarding and nothing advances.
class SelectionBinding {
  const SelectionBinding({required this.selected, required this.onToggle});

  final Set<String> selected;
  final void Function(String optionId) onToggle;
}

class ChoiceStepContent extends ConsumerWidget {
  const ChoiceStepContent({super.key, required this.step, this.binding});

  final ChoiceStep step;
  final SelectionBinding? binding;

  static const _defaultAdvanceDelay = Duration(milliseconds: 450);

  void _handleTap(
    WidgetRef ref,
    String optionId, {
    Duration advanceDelay = _defaultAdvanceDelay,
  }) {
    HapticFeedback.mediumImpact();
    if (binding != null) {
      binding!.onToggle(optionId);
      return;
    }
    final controller = ref.read(onboardingControllerProvider.notifier);
    controller.toggleOption(
      step.id,
      optionId,
      multi: step.selection == ChoiceSelection.multi,
    );
    if (step.autoAdvance) {
      Future.delayed(advanceDelay, () {
        if (controller.currentStep.id == step.id) controller.next();
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<String> selected =
        binding?.selected ??
        ref.watch(
          onboardingControllerProvider.select(
            (s) => s.selections[step.id] ?? const <String>{},
          ),
        );

    if (step.layout == ChoiceLayout.slider) {
      return StepReveal(
        index: 0,
        child: LevelSliderContent(
          options: step.options,
          selectedId: selected.firstOrNull,
          onSelect: (id) => _handleTap(ref, id),
        ),
      );
    }

    if (step.layout == ChoiceLayout.grid) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.screenBottomCta,
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: step.options.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: step.gridColumns,
            childAspectRatio: step.gridAspectRatio,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (context, i) => StepReveal(
            index: i,
            child: ChoiceGridTile(
              option: step.options[i],
              selected: selected.contains(step.options[i].id),
              onTap: () => _handleTap(ref, step.options[i].id),
            ),
          ),
        ),
      );
    }

    return _ResponsiveList(
      itemCount: step.options.length,
      itemBuilder: (itemHeight, i) => StepReveal(
        index: i,
        child: ChoiceListTile(
          option: step.options[i],
          selected: selected.contains(step.options[i].id),
          onTap: () => _handleTap(ref, step.options[i].id),
          multi: step.selection == ChoiceSelection.multi,
          minHeight: itemHeight,
        ),
      ),
    );
  }
}

/// Lays out a run of choice cards to fill whatever height they're given
/// (fed by [_ChapterScaffold.contentFillsHeight]) instead of sitting at
/// their own intrinsic size with empty space left over below — each card
/// gets an equal share of the available height, clamped to a sane range so
/// a long list degrades to a normal scroll instead of shrinking illegibly.
class _ResponsiveList extends StatelessWidget {
  const _ResponsiveList({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final Widget Function(double itemHeight, int index) itemBuilder;

  static const _minItemHeight = 96.0;
  static const _maxItemHeight = 240.0;

  /// With only a few options (Home / Gym / Both) filling the screen makes
  /// the cards absurdly tall, so they stay at a normal height.
  static const _maxItemHeightFewOptions = 132.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      child: Builder(
        builder: (context) {
          // The page scroll (in the chapter scaffold) owns scrolling; this
          // list just sizes its cards to the room left below the headline.
          final available =
              OnboardingViewport.maybeOf(context) ?? _maxItemHeight * itemCount;
          final itemHeight = (available / itemCount).clamp(
            _minItemHeight,
            itemCount <= 3 ? _maxItemHeightFewOptions : _maxItemHeight,
          );
          return Column(
            children: [
              for (var i = 0; i < itemCount; i++) itemBuilder(itemHeight, i),
            ],
          );
        },
      ),
    );
  }
}
