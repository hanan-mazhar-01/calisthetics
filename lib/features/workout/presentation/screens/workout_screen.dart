import 'package:flutter/material.dart';

import '../../../media/data/exercise_videos.dart';
import '../../data/background_music.dart';
import '../widgets/equalizer_icon.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../exercises/domain/exercise_lookup.dart';
import '../../../user/domain/completed_session.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../domain/step_labels.dart';
import '../../domain/workout_request.dart';
import '../../domain/workout_state.dart';
import '../providers/workout_controller.dart';
import '../widgets/player_chrome.dart';
import '../widgets/workout_complete_view.dart';
import '../widgets/workout_dialogs.dart';
import '../widgets/workout_video.dart';

/// The workout player. Only layout lives here; the logic is in
/// [WorkoutController] / [WorkoutState].
///
/// One persistent column — top section, video sheet, bottom section — so the
/// single video controller keeps playing while the sections animate.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key, required this.request});
  final WorkoutRequest request;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  bool _detailsOpen = false;

  /// The looping background track under the videos.
  final _music = BackgroundMusic();
  bool? _musicPlaying;
  bool? _musicDucked;

  @override
  void dispose() {
    _music.dispose();
    super.dispose();
  }

  /// Keeps the background music in step with the workout: on while the
  /// music switch is on and the workout runs, low while a video talks.
  void _syncMusic({required bool playing, required bool ducked}) {
    if (_musicPlaying != playing) {
      _musicPlaying = playing;
      _music.setPlaying(playing);
    }
    if (_musicDucked != ducked) {
      _musicDucked = ducked;
      _music.setDucked(ducked);
    }
  }

  WorkoutRequest get request => widget.request;

  bool _closing = false;

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _quit() async {
    // A try-out has nothing to lose: the cross just goes back.
    if (request.demo) {
      _close();
      return;
    }
    final ctl = ref.read(workoutControllerProvider(request).notifier);
    final wasPaused = ref.read(workoutControllerProvider(request)).paused;
    ctl.setPaused(true);
    final decision = await showQuitDialog(context, percent: ctl.percentDone);
    if (!decision.quit) {
      ctl.setPaused(wasPaused);
      return;
    }
    await ctl.quit(markComplete: decision.markComplete);
    if (mounted) _close();
  }

  void _toggleMusic() {
    final on = (ref.read(settingsProvider)['musicEnabled'] as bool?) ?? true;
    ref.read(settingsProvider.notifier).set('musicEnabled', !on);
  }

  Widget _transition(Widget child, Animation<double> a) => FadeTransition(
    opacity: a,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(a),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final provider = workoutControllerProvider(request);
    final phase = ref.watch(provider.select((s) => s.phase));
    if (phase == WorkoutPhase.done && request.demo) {
      // Time is up: go back to the exercise page.
      if (!_closing) {
        _closing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _close();
        });
      }
      return Scaffold(backgroundColor: c.background);
    }
    if (phase == WorkoutPhase.done) {
      _syncMusic(playing: false, ducked: false);
      return Scaffold(
        backgroundColor: c.background,
        body: WorkoutCompleteView(request: request, onClose: _close),
      );
    }

    final state = ref.watch(provider);
    final ctl = ref.read(provider.notifier);
    final interlude =
        phase == WorkoutPhase.preview || phase == WorkoutPhase.rest;
    final musicOn =
        (ref.watch(settingsProvider)['musicEnabled'] as bool?) ?? true;
    // The set's video speaks (rest clips are silent): duck the music then.
    _syncMusic(
      playing: musicOn && !state.paused,
      ducked:
          phase == WorkoutPhase.work &&
          ExerciseVideos.has(exerciseByNumber(state.step.exerciseNumber)),
    );
    // Get the next exercise's clip and video onto the phone during this set.
    final upNext = state.nextStep?.exerciseNumber;
    if (phase == WorkoutPhase.work && upNext != null) {
      final e = exerciseByNumber(upNext);
      ExerciseVideos.save(e, clip: true);
      ExerciseVideos.save(e);
    }
    final key = ValueKey('${phase.name}-${state.index}');
    final switchDuration = motion(context, 250);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _quit();
      },
      child: Scaffold(
        backgroundColor: c.background,
        body: Column(
          children: [
            AnimatedSwitcher(
              duration: switchDuration,
              transitionBuilder: _transition,
              child: KeyedSubtree(
                key: key,
                child: switch (phase) {
                  WorkoutPhase.preview || WorkoutPhase.rest => _InterludeTop(
                    state: state,
                    countdown: ctl.countdown,
                    onQuit: _quit,
                    onExtend: ctl.extendRest,
                    onSkip: ctl.skipRest,
                  ),
                  WorkoutPhase.work => _ActiveTop(
                    state: state,
                    countdown: ctl.countdown,
                    detailsOpen: _detailsOpen,
                    onQuit: _quit,
                    onToggleDetails: () =>
                        setState(() => _detailsOpen = !_detailsOpen),
                    onMusic: _toggleMusic,
                  ),
                  _ => _RatingTop(state: state, onQuit: _quit),
                },
              ),
            ),
            Expanded(
              child: AnimatedContainer(
                duration: switchDuration,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(interlude ? 28 : 0),
                  ),
                ),
                child: WorkoutVideo(
                  exerciseNumber: state.displayExercise,
                  paused: state.paused,
                  // Rest and "up next" show the short silent clip; the set
                  // plays the full video with its own coaching sound (the
                  // music switch only affects the background track).
                  clip: interlude,
                  onLoading: ctl.setVideoLoading,
                  sound: true,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: switchDuration,
              transitionBuilder: _transition,
              child: KeyedSubtree(
                key: key,
                child: switch (phase) {
                  WorkoutPhase.work => _ActiveBottom(
                    state: state,
                    countdown: ctl.countdown,
                    onTogglePause: () => ctl.setPaused(!state.paused),
                    onDone: ctl.finishStep,
                    onPrevious: ctl.previousStep,
                    onAudio: _toggleMusic,
                  ),
                  WorkoutPhase.rating => _RatingBottom(onRate: ctl.rate),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _name(WorkoutState s) => exerciseByNumber(s.step.exerciseNumber).name;

/// "FIRST UP" / "REST": pale gradient, big countdown with +10s, Skip.
class _InterludeTop extends StatelessWidget {
  const _InterludeTop({
    required this.state,
    required this.countdown,
    required this.onQuit,
    required this.onExtend,
    required this.onSkip,
  });
  final WorkoutState state;
  final ValueNotifier<int> countdown;
  final VoidCallback onQuit;
  final VoidCallback onExtend;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final first = state.isIntro;
    final h = (MediaQuery.sizeOf(context).height * 0.47).clamp(330.0, 460.0);
    return Container(
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.surfaceMuted, c.background],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlayerRoundButton(
                icon: Icons.close_rounded,
                tooltip: 'Quit workout',
                onPressed: onQuit,
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        first ? 'FIRST UP' : 'REST',
                        style: AppTypography.title(20, c.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      // The +10s pill sits inside the row's bounds (a Stack child
                      // outside its parent can't be tapped).
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(width: 64),
                            CountdownText(listenable: countdown, size: 64),
                            SizedBox(
                              width: 64,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 6, top: 4),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: ExtendPill(onPressed: onExtend),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      PlayerPill(
                        label: 'Skip',
                        primary: true,
                        onPressed: onSkip,
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                'Step ${state.index + 1}/${state.steps.length}',
                style: AppTypography.body(c.textMuted, fontSize: 13),
              ),
              Text(
                first ? _name(state) : 'Next: ${_name(state)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.title(17, c.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared top of the active and rating layouts: progress bar + buttons.
class _BarAndButtons extends ConsumerWidget {
  const _BarAndButtons({
    required this.state,
    required this.onQuit,
    this.onMusic,
  });
  final WorkoutState state;
  final VoidCallback onQuit;
  final VoidCallback? onMusic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = (ref.watch(settingsProvider)['musicEnabled'] as bool?) ?? true;
    final filled = state.index + 1;
    return Column(
      children: [
        SegmentedProgressBar(total: state.steps.length, filled: filled),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PlayerRoundButton(
              icon: Icons.close_rounded,
              tooltip: 'Quit workout',
              onPressed: onQuit,
            ),
            if (onMusic != null)
              PlayerRoundButton(
                icon: on ? Icons.music_note_rounded : Icons.music_off_rounded,
                tooltip: on ? 'Turn music off' : 'Turn music on',
                onPressed: onMusic!,
              ),
          ],
        ),
      ],
    );
  }
}

class _ActiveTop extends StatelessWidget {
  const _ActiveTop({
    required this.state,
    required this.countdown,
    required this.detailsOpen,
    required this.onQuit,
    required this.onToggleDetails,
    required this.onMusic,
  });
  final WorkoutState state;
  final ValueNotifier<int> countdown;
  final bool detailsOpen;
  final VoidCallback onQuit;
  final VoidCallback onToggleDetails;
  final VoidCallback onMusic;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final step = state.step;
    final ex = exerciseByNumber(step.exerciseNumber);
    final label = step.progressLabel;
    final next = state.nextStep;
    return ColoredBox(
      color: c.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BarAndButtons(state: state, onQuit: onQuit, onMusic: onMusic),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (step.isTimed)
                          CountdownText(listenable: countdown, size: 44)
                        else
                          Text(
                            step.targetLabel,
                            style: timerStyle(c.textPrimary, 44),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          ex.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title(18, c.textPrimary),
                        ),
                        if (label.isNotEmpty)
                          Text(
                            label,
                            style: AppTypography.body(
                              c.textMuted,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PlayerRoundButton(
                    icon: detailsOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    tooltip: detailsOpen ? 'Hide details' : 'Show details',
                    onPressed: onToggleDetails,
                  ),
                ],
              ),
              AnimatedSize(
                duration: motion(context, 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: detailsOpen
                    ? Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: c.softRose,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailLine('Target', step.targetLabel),
                            if (ex.cues != null && ex.cues!.isNotEmpty)
                              _DetailLine('Cues', ex.cues!),
                            _DetailLine(
                              'Next up',
                              next == null
                                  ? 'Last one'
                                  : next.exerciseNumber == step.exerciseNumber
                                  ? 'Set ${next.setNumber} of ${next.totalSets}'
                                  : exerciseByNumber(next.exerciseNumber).name,
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.title, this.body);
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$title  ',
              style: AppTypography.title(13, c.accentText),
            ),
            TextSpan(
              text: body,
              style: AppTypography.body(c.textPrimary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveBottom extends ConsumerWidget {
  const _ActiveBottom({
    required this.state,
    required this.countdown,
    required this.onTogglePause,
    required this.onDone,
    required this.onPrevious,
    required this.onAudio,
  });
  final WorkoutState state;
  final ValueNotifier<int> countdown;
  final VoidCallback onTogglePause;
  final VoidCallback onDone;
  final VoidCallback onPrevious;
  final VoidCallback onAudio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final step = state.step;
    final on = (ref.watch(settingsProvider)['musicEnabled'] as bool?) ?? true;
    return ColoredBox(
      color: c.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StepCapsule(
                countdown: step.isTimed ? countdown : null,
                total: step.seconds ?? 0,
                onPrevious: state.index == 0 ? null : onPrevious,
                onNext: onDone,
                showSkips: !state.demo,
                center: step.isTimed
                    ? IconButton(
                        tooltip: state.paused ? 'Resume' : 'Pause',
                        onPressed: onTogglePause,
                        icon: AnimatedSwitcher(
                          duration: motion(context, 180),
                          child: Icon(
                            state.paused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            key: ValueKey(state.paused),
                            size: 30,
                            color: c.textPrimary,
                          ),
                        ),
                      )
                    : PlayerPill(
                        label: 'Done',
                        primary: true,
                        height: 46,
                        onPressed: onDone,
                      ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: on ? 'Music on' : 'Music off',
                    child: InkWell(
                      onTap: onAudio,
                      borderRadius: BorderRadius.circular(999),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: on ? c.surfaceSelected : c.surfaceMuted,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            EqualizerIcon(
                              active: on && !state.paused,
                              color: on ? c.accentText : c.textMuted,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              on ? 'Music on' : 'Music off',
                              style: AppTypography.body(
                                on ? c.textPrimary : c.textSecondary,
                                fontSize: 14,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingTop extends StatelessWidget {
  const _RatingTop({required this.state, required this.onQuit});
  final WorkoutState state;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return ColoredBox(
      color: c.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BarAndButtons(state: state, onQuit: onQuit),
              const SizedBox(height: 16),
              Text(
                _name(state),
                style: AppTypography.title(18, c.textSecondary),
              ),
              Text(
                'How did that feel?',
                style: AppTypography.title(
                  26,
                  c.textPrimary,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingBottom extends StatelessWidget {
  const _RatingBottom({required this.onRate});
  final ValueChanged<Effort?> onRate;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return ColoredBox(
      color: c.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  for (final (label, effort) in _ratingChoices) ...[
                    Expanded(
                      child: PlayerPill(
                        label: label,
                        onPressed: () => onRate(effort),
                      ),
                    ),
                    if (effort != _ratingChoices.last.$2)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
              TextButton(
                onPressed: () => onRate(null),
                child: Text(
                  'Skip',
                  style: AppTypography.body(c.textMuted, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _ratingChoices = [
  ('Easy', Effort.easy),
  ('Just right', Effort.justRight),
  ('Hard', Effort.hard),
];
