import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/domain/achievement_evaluator.dart';
import '../widgets/achievement_decor.dart';
import '../widgets/achievement_text.dart';
import '../widgets/medal_badge.dart';
import 'achievement_share_screen.dart';

/// Full-screen celebration for an earned medal: stage lights, confetti, the
/// medal, its name and date, and a Share button.
class AchievementCelebrationScreen extends StatefulWidget {
  const AchievementCelebrationScreen({super.key, required this.achievement});
  final Achievement achievement;

  @override
  State<AchievementCelebrationScreen> createState() =>
      _AchievementCelebrationScreenState();
}

class _AchievementCelebrationScreenState
    extends State<AchievementCelebrationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
    } else if (!_enter.isAnimating && _enter.value == 0) {
      _enter.forward();
      _confetti.repeat();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final a = widget.achievement;
    final pad = MediaQuery.paddingOf(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final bg = c.cover;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            Positioned.fill(child: SpotlightBeams(color: c.accent)),
            if (!still)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _confetti,
                  builder: (context, _) => ConfettiLayer(
                    t: _confetti.value,
                    palette: [
                      c.accent,
                      c.softRose,
                      c.warning,
                      c.highlight,
                      Colors.white,
                    ],
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                pad.top + 14,
                24,
                pad.bottom + 24,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 44),
                      Expanded(
                        child: Text(
                          'ACHIEVEMENT',
                          textAlign: TextAlign.center,
                          style: AppTypography.title(
                            18,
                            c.onCover,
                            weight: FontWeight.w700,
                          ).copyWith(letterSpacing: 0.6),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Close',
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).pop(),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(Icons.close_rounded, color: c.onCover),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _enter,
                        builder: (context, child) {
                          final t = Curves.easeOutBack.transform(
                            _enter.value.clamp(0.0, 1.0),
                          );
                          return Opacity(
                            opacity: _enter.value.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.55 + 0.45 * t,
                              child: child,
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    c.accent.withValues(alpha: 0.35),
                                    c.accent.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                            MedalBadge(
                              number: a.number,
                              unit: a.unit,
                              earned: true,
                              size: 290,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Text(
                    a.title,
                    textAlign: TextAlign.center,
                    style: AppTypography.title(
                      32,
                      c.onCover,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (a.unlockedAt != null)
                    Text(
                      medalDate(a.unlockedAt!),
                      style: AppTypography.body(c.coverAccent, fontSize: 16),
                    ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      celebrationText(a),
                      textAlign: TextAlign.center,
                      style: AppTypography.body(
                        c.onCover.withValues(alpha: 0.85),
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Semantics(
                    button: true,
                    label: 'Share',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          fullscreenDialog: true,
                          builder: (_) =>
                              AchievementShareScreen(achievement: a),
                        ),
                      ),
                      child: Container(
                        height: 54,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'SHARE',
                          style: AppTypography.title(
                            16,
                            Colors.black,
                            weight: FontWeight.w800,
                          ).copyWith(letterSpacing: 0.8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
