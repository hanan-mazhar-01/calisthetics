import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../onboarding/data/onboarding_flow.dart';
import '../../../plans/domain/user_profile.dart';
import '../../../onboarding/domain/onboarding_step.dart';
import '../../../onboarding/presentation/widgets/choice_step_content.dart';
import '../../../onboarding/presentation/widgets/focus_step_content.dart';
import '../../../onboarding/presentation/widgets/onboarding_continue_bar.dart';
import '../../../onboarding/presentation/widgets/onboarding_scroll_body.dart';
import '../../../onboarding/presentation/widgets/onboarding_titled_header.dart';
import '../providers/plan_settings_draft.dart';

enum PlanOption {
  focus('focus-areas'),
  level('training-experience'),
  duration('workout-duration'),
  avoid('areas-to-protect');

  const PlanOption(this.stepId);

  /// The onboarding step whose question and cards this option reuses.
  final String stepId;
}

/// Edits one plan preference on the same screen the user saw in onboarding
/// (same headline, same cards or body map), then "Save" returns to the plan
/// settings. Choices go to the settings draft, not to onboarding answers.
class PlanOptionEditScreen extends ConsumerWidget {
  const PlanOptionEditScreen({super.key, required this.option});

  final PlanOption option;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final draft = ref.watch(planDraftProvider);
    final notifier = ref.read(planDraftProvider.notifier);
    final step = onboardingSteps.firstWhere((s) => s.id == option.stepId);

    final Widget header;
    final Widget content;
    final bool fills;
    switch (step) {
      case ChoiceStep():
        final binding = _bindingFor(ref, option, draft, notifier);
        header = OnboardingTitledHeader(
          headline: step.headline,
          subtitle: step.subtitle,
        );
        content = ChoiceStepContent(step: step, binding: binding);
        fills = step.layout == ChoiceLayout.list;
      case FocusStep():
        header = OnboardingTitledHeader(headline: step.headline);
        content = FocusStepContent(
          step: step,
          binding: SelectionBinding(
            selected: draft.focusAreas,
            onToggle: (id) {
              final next = {...ref.read(planDraftProvider).focusAreas};
              if (!next.add(id)) next.remove(id);
              notifier.setFocus(next);
            },
          ),
        );
        fills = false;
      default:
        throw StateError('Unsupported step for ${option.name}');
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.softRose, c.background],
            stops: const [0, 0.38],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GlassButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Expanded(
                child: OnboardingScrollBody(
                  fillsHeight: fills,
                  header: header,
                  content: content,
                ),
              ),
              OnboardingContinueBar(
                label: 'Save',
                enabled: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SelectionBinding _bindingFor(
    WidgetRef ref,
    PlanOption option,
    UserProfile draft,
    PlanDraft notifier,
  ) {
    switch (option) {
      case PlanOption.level:
        return SelectionBinding(
          selected: {ref.watch(planDraftExperienceProvider)},
          onToggle: (id) =>
              ref.read(planDraftExperienceProvider.notifier).choose(id),
        );
      case PlanOption.duration:
        return SelectionBinding(
          selected: {durationOptionId(draft.sessionMinutes)},
          onToggle: (id) => notifier.setMinutes(durationFromOptionId(id)),
        );
      case PlanOption.avoid:
        return SelectionBinding(
          selected: areaOptionIds(draft.protectedAreas),
          onToggle: (id) {
            // "None" is exclusive: it clears the rest, and any area clears it.
            if (id == 'none') {
              notifier.setAvoid(<ProtectedArea>{});
              return;
            }
            final area = areasFromOptionIds(<String>{id}).single;
            final next = <ProtectedArea>{
              ...ref.read(planDraftProvider).protectedAreas,
            };
            if (!next.add(area)) next.remove(area);
            notifier.setAvoid(next);
          },
        );
      case PlanOption.focus:
        throw StateError('Focus uses the body map');
    }
  }
}
