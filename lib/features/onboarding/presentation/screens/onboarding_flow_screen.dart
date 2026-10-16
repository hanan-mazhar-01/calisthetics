import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/motion/calesthetics_motion.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../paywall/presentation/widgets/paywall_content.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../domain/onboarding_plan_summary.dart';
import '../../domain/onboarding_step.dart';
import '../onboarding_dynamic_content.dart';
import '../providers/onboarding_controller.dart';
import '../widgets/choice_step_content.dart';
import '../widgets/compare_step_content.dart';
import '../widgets/account_step_view.dart';
import '../widgets/curve_step_content.dart';
import '../widgets/focus_step_content.dart';
import '../widgets/health_note_step_content.dart';
import '../widgets/loading_step_view.dart';
import '../widgets/milestones_step_content.dart';
import '../widgets/mosaic_step_view.dart';
import '../widgets/name_step_content.dart';
import '../widgets/onboarding_chrome.dart';
import '../widgets/onboarding_continue_bar.dart';
import '../widgets/onboarding_titled_header.dart';
import '../widgets/onboarding_scroll_body.dart';
import '../widgets/pair_step_content.dart';
import '../widgets/part_intro_step_view.dart';
import '../widgets/photo_question_step_view.dart';
import '../widgets/plan_content_step_view.dart';
import '../widgets/plan_preview_step_view.dart';
import '../widgets/plank_step_content.dart';
import '../widgets/plans_step_content.dart';
import '../widgets/reveal_step_view.dart';
import '../widgets/welcome_step_view.dart';
import '../widgets/win_step_content.dart';

/// Stable across rebuilds (there's exactly one Name screen in the flow) so
/// the Continue button can reach into [NameStepContentState] and await its
/// closing animation before navigating — see [_ChapterScaffold.beforeContinue].
final _nameStepContentKey = GlobalKey<NameStepContentState>();

/// The chrome shell for the whole onboarding flow: owns nothing itself, just
/// reads [OnboardingController] and swaps the body per step with a shared
/// slide/fade transition, matching the reference's single-page-app feel.
///
/// The transition is direction-aware: moving forward, the new step enters
/// from the right and the old one exits to the left; going back, it's
/// mirrored. [_forward] is derived by comparing this build's step index to
/// the previous one, so it costs nothing extra to track.
class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  int? _previousIndex;
  bool _forward = true;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final index = ref.watch(
      onboardingControllerProvider.select((s) => s.index),
    );
    final step = controller.currentStep;

    if (_previousIndex != null && index != _previousIndex) {
      _forward = index > _previousIndex!;
    }
    _previousIndex = index;

    return PopScope(
      canPop: controller.isFirstStep,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.back();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.appColors.softRose,
                context.appColors.background,
              ],
              stops: [0, 0.38],
            ),
          ),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: AppDurations.stepTransition,
              switchInCurve: AppCurves.standard,
              switchOutCurve: AppCurves.standard,
              transitionBuilder: (child, animation) {
                final isOutgoing = animation.status == AnimationStatus.reverse;
                final dx = isOutgoing
                    ? (_forward ? -0.04 : 0.04)
                    : (_forward ? 0.04 : -0.04);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(dx, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(step.id),
                child: _StepBody(step: step),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepBody extends ConsumerWidget {
  const _StepBody({required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);

    final selections = ref.watch(
      onboardingControllerProvider.select((s) => s.selections),
    );
    final plankSeconds = ref.watch(
      onboardingControllerProvider.select((s) => s.plankSeconds),
    );
    final plan = OnboardingPlanSummary.from(
      selections,
      plankSeconds: plankSeconds,
      today: ref.read(clockProvider)(),
    );
    final OnboardingStep current = applyDynamicContent(
      step,
      plan: plan,
      plankSeconds: plankSeconds,
    );

    Future<void> advance() => _advance(context, controller);

    return switch (current) {
      WelcomeStep() => WelcomeStepView(onStart: advance),
      PartIntroStep() => Column(
        children: [
          Expanded(child: PartIntroStepView(step: current)),
          OnboardingContinueBar(
            label: current.ctaLabel,
            enabled: true,
            onPressed: advance,
          ),
        ],
      ),
      ChoiceStep() => _ChapterScaffold(
        step: current,
        headline: current.headline,
        subtitle: current.subtitle,
        content: ChoiceStepContent(step: current),
        continueEnabled:
            current.optional ||
            ref.watch(
              onboardingControllerProvider.select(
                (s) =>
                    (s.selections[current.id] ?? const <String>{}).isNotEmpty,
              ),
            ),
        contentFillsHeight: current.layout == ChoiceLayout.list,
      ),
      CurveStep() => _ChapterScaffold(
        step: current,
        headline: current.headline,
        content: CurveStepContent(step: current),
        continueEnabled: true,
        ctaLabel: current.ctaLabel,
      ),
      NameStep() => _ChapterScaffold(
        step: current,
        headline: current.headline,
        content: NameStepContent(key: _nameStepContentKey),
        continueEnabled: ref.watch(
          onboardingControllerProvider.select((s) => s.name.trim().isNotEmpty),
        ),
        beforeContinue: () =>
            _nameStepContentKey.currentState?.playCloseAnimation() ??
            Future.value(),
      ),
      WinStep() => _ChapterScaffold(
        step: current,
        headline: Headline(
          controller.interpolateName(current.headline.lead),
          current.headline.accent,
          controller.interpolateName(current.headline.tail),
        ),
        subtitle: current.subtitle,
        content: WinStepContent(plan: plan),
        continueEnabled: true,
      ),
      PlankStep() => _ChapterScaffold(
        step: current,
        headline: current.headline,
        subtitle: current.subtitle,
        content: const PlankStepContent(),
        continueEnabled: true,
      ),
      CompareStep() => _ChapterScaffold(
        step: current,
        headline: current.headline,
        content: CompareStepContent(step: current),
        continueEnabled: true,
      ),
      MilestonesStep() => _ChapterScaffold(
        step: current,
        headline: current.headline,
        content: MilestonesStepContent(step: current),
        continueEnabled: true,
      ),
      FocusStep() => _ChapterScaffold(
        step: current,
        headline: current.headline,
        content: FocusStepContent(step: current),
        continueEnabled: ref.watch(
          onboardingControllerProvider.select(
            (s) => (s.selections[current.id] ?? const <String>{}).isNotEmpty,
          ),
        ),
      ),
      PairStep() => _ChapterScaffold(
        step: current,
        headline: current.headline,
        content: const PairStepContent(),
        continueEnabled: true,
      ),
      PhotoQuestionStep() => PhotoQuestionStepView(
        step: current,
        onNext: advance,
      ),
      HealthNoteStep() => _ChapterScaffold(
        step: current,
        headline: current.headline,
        subtitle: current.subtitle,
        content: const HealthNoteStepContent(),
        continueEnabled: ref.watch(
          onboardingControllerProvider.select(
            (s) => (s.selections[healthNoteStepId] ?? const <String>{})
                .contains(healthNoteAcknowledged),
          ),
        ),
      ),
      PlansStep() => _ChapterScaffold(
        step: current,
        headline: current.headline,
        subtitle: current.subtitle,
        content: const PlansStepContent(),
        continueEnabled: true,
      ),
      LoadingStep() => LoadingStepView(step: current, onNext: advance),
      RevealStep() => RevealStepView(step: current, onNext: advance),
      PlanContentStep() => PlanContentStepView(step: current, onNext: advance),
      PlanPreviewStep() => PlanPreviewStepView(step: current, onNext: advance),
      PaywallStep() => PaywallContent(onClose: advance),
      AccountStep() => AccountStepView(
        onSkip: advance,
        onBack: controller.back,
      ),
      MosaicStep() => MosaicStepView(step: current, onNext: advance),
    };
  }
}

/// Moves to the next step; on the last one, starts the chosen plan and enters
/// the main app.
Future<void> _advance(
  BuildContext context,
  OnboardingController controller,
) async {
  if (controller.isLastStep) {
    await controller.startPlanAndFinish();
    if (!context.mounted) return;
    context.go('/home');
  } else {
    controller.next();
  }
}

/// Shared chrome + titled header + scrollable content + optional continue
/// bar, used by every step type except Welcome and the chapter dividers
/// (which own their full layout).
class _ChapterScaffold extends ConsumerWidget {
  const _ChapterScaffold({
    required this.step,
    required this.headline,
    this.subtitle,
    required this.content,
    required this.continueEnabled,
    this.ctaLabel = 'Continue',
    this.beforeContinue,
    this.contentFillsHeight = false,
  });

  final OnboardingStep step;
  final Headline headline;
  final String? subtitle;
  final Widget content;
  final bool continueEnabled;
  final String ctaLabel;

  /// When true, `content` gets the exact remaining height below the header
  /// (no scroll wrapper) so it can distribute that space among its own
  /// children responsively — used by list-choice screens so the cards grow
  /// to fill the screen instead of sitting short with empty space below.
  final bool contentFillsHeight;

  /// Awaited before advancing — lets a screen (e.g. the Name step's folder
  /// animation) play a closing beat first instead of navigating instantly.
  final Future<void> Function()? beforeContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final progress = controller.chapterProgress;
    return Column(
      children: [
        CalestheticsFadeSlide(
          duration: const Duration(milliseconds: 280),
          offset: 10,
          child: OnboardingChrome(
            onBack: controller.back,
            chapter: step.chapter!,
            stepInChapter: progress.step,
            stepsInChapter: progress.total,
          ),
        ),
        // Only the progress bar and the Continue button stay put; the headline
        // and the content scroll together between them.
        Expanded(
          child: OnboardingScrollBody(
            fillsHeight: contentFillsHeight,
            header: CalestheticsFadeSlide(
              delay: const Duration(milliseconds: 60),
              duration: const Duration(milliseconds: 340),
              offset: 18,
              child: OnboardingTitledHeader(
                headline: headline,
                subtitle: subtitle,
              ),
            ),
            content: CalestheticsFadeSlide(
              delay: const Duration(milliseconds: 130),
              duration: const Duration(milliseconds: 360),
              offset: 26,
              child: content,
            ),
          ),
        ),
        if (step.showsContinueCta)
          CalestheticsFadeSlide(
            delay: const Duration(milliseconds: 200),
            duration: const Duration(milliseconds: 300),
            offset: 14,
            child: OnboardingContinueBar(
              label: ctaLabel,
              enabled: continueEnabled,
              onPressed: () async {
                await beforeContinue?.call();
                if (!context.mounted) return;
                await _advance(context, controller);
              },
            ),
          ),
      ],
    );
  }
}
