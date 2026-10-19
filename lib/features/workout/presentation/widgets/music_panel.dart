import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../domain/music_settings.dart';

/// Opens the music panel just under [anchor] (the music button), aligned to
/// its right edge: a Music on/off switch and a volume slider for the
/// background track. Changes apply at once; tap outside to close.
Future<void> showMusicPanel(BuildContext anchor) {
  final box = anchor.findRenderObject() as RenderBox;
  final rect = box.localToGlobal(Offset.zero) & box.size;
  final still = MediaQuery.disableAnimationsOf(anchor);
  return showGeneralDialog<void>(
    context: anchor,
    barrierDismissible: true,
    barrierLabel: 'Close music settings',
    barrierColor: Colors.black.withValues(alpha: 0.28),
    transitionDuration: still
        ? Duration.zero
        : const Duration(milliseconds: 180),
    pageBuilder: (context, _, _) {
      final width = MediaQuery.sizeOf(context).width;
      return Stack(
        children: [
          Positioned(
            top: rect.bottom + 10,
            right: (width - rect.right).clamp(12.0, width),
            child: const MusicPanel(),
          ),
        ],
      );
    },
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        alignment: Alignment.topRight,
        child: child,
      ),
    ),
  );
}

/// The card itself: "Music" with an on/off switch, and below it the volume
/// of the background music only (the coach's voice in the videos stays as
/// it is). The slider is greyed out while the music is off.
class MusicPanel extends ConsumerWidget {
  const MusicPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final settings = ref.watch(settingsProvider);
    final on = musicEnabledIn(settings);
    final volume = musicVolumeIn(settings);
    final notifier = ref.read(settingsProvider.notifier);
    final percent = (volume * 100).round();

    return Material(
      color: c.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 292,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.accent.withValues(alpha: on ? 0.16 : 0.08),
                    ),
                    child: Icon(
                      on ? Icons.music_note_rounded : Icons.music_off_rounded,
                      size: 20,
                      color: on ? c.accentText : c.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Music',
                      style: AppTypography.title(
                        18,
                        c.textPrimary,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Semantics(
                    label: 'Music',
                    child: Switch(
                      key: const ValueKey('music-switch'),
                      value: on,
                      activeTrackColor: c.accent,
                      onChanged: (v) => notifier.set(musicEnabledKey, v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: on ? 1 : 0.45,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Volume',
                            style: AppTypography.body(
                              c.textSecondary,
                              fontSize: 14,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$percent%',
                            key: const ValueKey('music-percent'),
                            style: AppTypography.body(
                              c.textPrimary,
                              fontSize: 14,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.volume_mute_rounded,
                            size: 20,
                            color: c.textMuted,
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: c.accent,
                                inactiveTrackColor: c.accent.withValues(
                                  alpha: 0.2,
                                ),
                                thumbColor: c.accent,
                                disabledActiveTrackColor: c.textMuted,
                                disabledInactiveTrackColor: c.divider,
                                disabledThumbColor: c.textMuted,
                                overlayColor: c.accent.withValues(alpha: 0.14),
                                trackHeight: 5,
                              ),
                              child: Slider(
                                key: const ValueKey('music-volume'),
                                value: volume,
                                label: '$percent%',
                                semanticFormatterCallback: (v) =>
                                    '${(v * 100).round()} percent',
                                onChanged: on
                                    ? (v) => notifier.setLive(musicVolumeKey, v)
                                    : null,
                                onChangeEnd: on
                                    ? (v) => notifier.set(musicVolumeKey, v)
                                    : null,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.volume_up_rounded,
                            size: 20,
                            color: c.textMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  'Only the background music. The coach\'s voice in the '
                  'videos stays as it is.',
                  style: AppTypography.body(c.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
