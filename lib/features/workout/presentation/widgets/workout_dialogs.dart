import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/glass_sheet.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../domain/voice_cues.dart';

/// What she picked on the quit dialog.
class QuitDecision {
  const QuitDecision.keepGoing() : quit = false, markComplete = false;
  const QuitDecision.quit({required this.markComplete}) : quit = true;

  final bool quit;

  /// Quit and count this day as done (otherwise only the progress is kept).
  final bool markComplete;
}

/// "Quit workout?": keep going or quit, side by side, with a tick-box to mark
/// the day complete. [percent] is how far she has got.
Future<QuitDecision> showQuitDialog(
  BuildContext context, {
  required int percent,
}) async {
  final decision = await showDialog<QuitDecision>(
    context: context,
    builder: (context) {
      final c = context.appColors;
      var mark = false;
      return StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: c.surface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quit workout?',
                  style: AppTypography.title(
                    20,
                    c.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  percent > 0
                      ? "You're $percent% through. Quitting saves how far you got."
                      : "You haven't finished anything yet.",
                  style: AppTypography.body(c.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Semantics(
                  checked: mark,
                  label: 'Mark this day as complete',
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => mark = !mark),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                            color: mark ? c.accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: mark ? c.accent : c.textMuted,
                              width: 2,
                            ),
                          ),
                          child: mark
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: c.onAccent,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mark this day as complete',
                                style: AppTypography.title(
                                  15,
                                  c.textPrimary,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Counts this workout towards your plan and streak.',
                                style: AppTypography.body(
                                  c.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _QuitButton(
                        label: 'Keep going',
                        primary: true,
                        onTap: () => Navigator.pop(
                          context,
                          const QuitDecision.keepGoing(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuitButton(
                        label: 'Quit',
                        onTap: () => Navigator.pop(
                          context,
                          QuitDecision.quit(markComplete: mark),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return decision ?? const QuitDecision.keepGoing();
}

class _QuitButton extends StatelessWidget {
  const _QuitButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary ? c.accent : c.surfaceMuted,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: AppTypography.title(
              16,
              primary ? c.onAccent : c.textPrimary,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

/// Audio settings: voice cue level and the halfway prompt. There is no
/// music-service integration.
Future<void> showAudioSheet(BuildContext context) =>
    showGlassSheet<void>(context, builder: (_) => const _AudioSheet());

class _AudioSheet extends ConsumerWidget {
  const _AudioSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final settings = ref.watch(settingsProvider);
    final mode = VoiceCueMode.parse(settings['voiceCues']);
    final halfway = (settings['halfwayPrompt'] as bool?) ?? true;
    final notifier = ref.read(settingsProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Audio', style: AppTypography.title(20, c.textPrimary)),
        const SizedBox(height: 16),
        Text(
          'Voice cues',
          style: AppTypography.body(c.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<VoiceCueMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: VoiceCueMode.off, label: Text('Off')),
              ButtonSegment(value: VoiceCueMode.brief, label: Text('Brief')),
              ButtonSegment(
                value: VoiceCueMode.detailed,
                label: Text('Detailed'),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) => notifier.set('voiceCues', s.first.name),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Halfway prompt',
            style: AppTypography.body(c.textPrimary, weight: FontWeight.w600),
          ),
          value: halfway,
          onChanged: mode == VoiceCueMode.off
              ? null
              : (v) => notifier.set('halfwayPrompt', v),
        ),
        const SizedBox(height: 4),
        Text(
          "Spoken cues aren't available in this version yet. Your choice is saved for when they are.",
          style: AppTypography.body(c.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}
