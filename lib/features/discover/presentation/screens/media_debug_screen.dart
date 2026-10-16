import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass/app_background.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../exercises/data/exercise_catalog.dart';
import '../../../media/presentation/media_providers.dart';

/// Debug-only: which of the 98 unique videos and thumbnails resolve through
/// the media repository. Opened by a long-press on the Discover title in
/// debug builds; not routed.
class MediaDebugScreen extends ConsumerWidget {
  const MediaDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final repo = ref.watch(mediaRepositoryProvider);
    final unique = [
      for (final e in exerciseCatalog)
        if (!e.sharesVideo) e,
    ];
    final rows = [
      for (final e in unique)
        (e, repo.exerciseVideo(e), repo.exercisePoster(e)),
    ];
    final videos = rows.where((r) => r.$2 != null).length;
    final posters = rows.where((r) => r.$3 != null).length;
    return GradientScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  GlassButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Media check: videos $videos/${unique.length}, '
                      'thumbnails $posters/${unique.length}',
                      style: AppTypography.title(15, c.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, i) {
                  final (e, video, poster) = rows[i];
                  return ListTile(
                    dense: true,
                    title: Text(
                      '${e.number}. ${e.name}',
                      style: AppTypography.body(c.textPrimary, fontSize: 14),
                    ),
                    subtitle: Text(
                      e.videoFile,
                      style: AppTypography.body(c.textMuted, fontSize: 11),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Dot(label: 'V', ok: video != null),
                        const SizedBox(width: 8),
                        _Dot(label: 'T', ok: poster != null),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.label, required this.ok});
  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 16,
          color: ok ? c.success : c.warning,
        ),
        const SizedBox(width: 2),
        Text(label, style: AppTypography.body(c.textSecondary, fontSize: 11)),
      ],
    );
  }
}
