import 'package:flutter/material.dart';

import '../../../media/data/bunny_prefetch.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/motion/calesthetics_motion.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
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
import '../widgets/typewriter_text.dart';
import '../widgets/welcome_step_view.dart';
import '../widgets/win_step_content.dart';
import '../../../../core/haptics/haptics.dart';

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
  @override
  void initState() {
    super.initState();
    // Fetch the onboarding pictures in the background while the first
    // screens are shown.
    prefetchBunnyImages('onboarding/');
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    // Rebuild whenever the step changes.
    ref.watch(onboardingControllerProvider.select((s) => s.index));
    final step = controller.currentStep;

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
            // No cross-fade or slide between steps: the old screen must be
            // gone the moment the next one appears, so its text never
            // lingers under the new headline. The new screen brings its own
            // entrance (the headline types itself out, options step in).
            child: KeyedSubtree(
              key: ValueKey(step.id),
              child: _StepBody(step: step),
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

    // Someone already signed in (e.g. from "Log in" on the welcome screen)
    // never sees the sign-in step at the end: the paywall finishes it.
    final signedIn = ref.watch(currentUserProvider) != null;
    Future<void> advance() => _advance(context, controller, signedIn: signedIn);

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
        fixedContent: true,
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
      AccountStep() when signedIn => _FinishNow(onFinish: advance),
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
  OnboardingController controller, {
  required bool signedIn,
}) async {
  if (controller.isLastStep || (signedIn && controller.nextStepIsAccount)) {
    await controller.startPlanAndFinish();
    if (!context.mounted) return;
    context.go('/home');
  } else {
    controller.next();
  }
}

/// Shown for a moment if a signed-in user lands on the sign-in step (e.g.
/// the app was closed there): finishes onboarding straight away.
class _FinishNow extends StatefulWidget {
  const _FinishNow({required this.onFinish});
  final Future<void> Function() onFinish;

  @override
  State<_FinishNow> createState() => _FinishNowState();
}

class _FinishNowState extends State<_FinishNow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFinish());
  }

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// Shared chrome + titled header + scrollable content + optional continue
/// bar, used by every step type except Welcome and the chapter dividers
/// (which own their full layout).
class _ChapterScaffold extends ConsumerStatefulWidget {
  const _ChapterScaffold({
    required this.step,
    required this.headline,
    this.subtitle,
    required this.content,
    required this.continueEnabled,
    this.ctaLabel = 'Continue',
    this.beforeContinue,
    this.contentFillsHeight = false,
    this.fixedContent = false,
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

  /// The content fits the screen exactly and the page never scrolls.
  final bool fixedContent;

  /// Awaited before advancing — lets a screen (e.g. the Name step's folder
  /// animation) play a closing beat first instead of navigating instantly.
  final Future<void> Function()? beforeContinue;

  @override
  ConsumerState<_ChapterScaffold> createState() => _ChapterScaffoldState();
}

class _ChapterScaffoldState extends ConsumerState<_ChapterScaffold>
    with SingleTickerProviderStateMixin {
  /// Runs once the headline has finished typing: the content (cards,
  /// options, chart...) then comes in one piece after another.
  late final AnimationController _body = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  void _headlineTyped() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _body.value = 1;
    } else {
      _body.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final controller = ref.read(onboardingControllerProvider.notifier);
    final progress = controller.chapterProgress;
    return StepIntroScope(
      animation: _body,
      child: _layout(context, step, controller, progress),
    );
  }

  Widget _layout(
    BuildContext context,
    OnboardingStep step,
    OnboardingController controller,
    ({int step, int total}) progress,
  ) {
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
            fillsHeight: widget.contentFillsHeight,
            fixed: widget.fixedContent,
            header: OnboardingTitledHeader(
              headline: widget.headline,
              subtitle: widget.subtitle,
              onTyped: _headlineTyped,
            ),
            // Choice screens stagger their own options; everything else
            // comes in as one block.
            content: step is ChoiceStep
                ? widget.content
                : StepReveal(index: 0, child: widget.content),
          ),
        ),
        if (step.showsContinueCta)
          StepReveal(
            index: 5,
            child: OnboardingContinueBar(
              label: widget.ctaLabel,
              enabled: widget.continueEnabled,
              onPressed: () async {
                Haptics.medium();
                await widget.beforeContinue?.call();
                if (!context.mounted) return;
                await _advance(
                  context,
                  controller,
                  signedIn: ref.read(currentUserProvider) != null,
                );
              },
            ),
          ),
      ],
    );
  }
}
