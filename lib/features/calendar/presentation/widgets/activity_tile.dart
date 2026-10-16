import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../exercises/presentation/widgets/exercise_thumb.dart';
import '../../../user/domain/completed_session.dart';
import '../../domain/activity_log.dart';

/// One finished activity: picture, "Oct 13, 11:24 AM", name, "28 Mins · 8
/// exercises". Activities she logged by hand show an icon instead of a photo.
class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.session,
    this.onTap,
    this.onLongPress,
  });

  final CompletedSession session;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final minutes = (session.durationSeconds / 60).round();
    final n = session.exerciseNumbers.length;
    final detail = n == 0
        ? '$minutes Mins'
        : '$minutes Mins · $n ${n == 1 ? 'exercise' : 'exercises'}';
    return Semantics(
      button: onTap != null,
      label:
          '${session.sessionName}, ${activityStamp(session.finishedAt)}, $detail',
      onLongPressHint: onLongPress == null ? null : 'Delete activity',
      onLongPress: onLongPress,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          height: 98,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              SizedBox(
                width: 116,
                height: 98,
                child: n > 0 && !session.isManual
                    ? ExerciseThumb(
                        number: session.exerciseNumbers.first,
                        size: 116,
                        radiusFactor: 0,
                      )
                    : ColoredBox(
                        color: c.softRose,
                        child: Icon(
                          Icons.directions_run_rounded,
                          size: 36,
                          color: c.accentText,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activityStamp(session.finishedAt),
                      style: AppTypography.body(c.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      session.sessionName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title(
                        17,
                        c.textPrimary,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      style: AppTypography.body(
                        c.textSecondary,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
