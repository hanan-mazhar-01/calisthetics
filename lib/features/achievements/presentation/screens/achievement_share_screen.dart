import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/domain/achievement_evaluator.dart';
import '../widgets/achievement_text.dart';
import '../widgets/medal_badge.dart';

/// "Share": the medal on a card, and a button that hands the card to the
/// system share sheet as an image.
class AchievementShareScreen extends StatefulWidget {
  const AchievementShareScreen({super.key, required this.achievement});
  final Achievement achievement;

  @override
  State<AchievementShareScreen> createState() => _AchievementShareScreenState();
}

class _AchievementShareScreenState extends State<AchievementShareScreen> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      final a = widget.achievement;
      await SharePlus.instance.share(
        ShareParams(
          text: 'I earned "${a.title}" on Calesthetics.',
          files: [
            XFile.fromData(
              data.buffer.asUint8List(),
              mimeType: 'image/png',
              name: 'calesthetics_${a.id}.png',
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final a = widget.achievement;
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: c.softRose,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, pad.top + 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'SHARE',
                    style: AppTypography.title(
                      20,
                      c.textPrimary,
                      weight: FontWeight.w800,
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
                      width: 48,
                      height: 48,
                      child: Icon(Icons.close_rounded, color: c.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 0.62,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: _ShareCard(achievement: a),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 22, 24, pad.bottom + 22),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Tap to share',
                  style: AppTypography.title(
                    20,
                    c.textPrimary,
                    weight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  label: 'Share image',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: _share,
                    child: Column(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: c.accent,
                            shape: BoxShape.circle,
                          ),
                          child: _busy
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: c.onAccent,
                                  ),
                                )
                              : Icon(
                                  Icons.ios_share_rounded,
                                  color: c.onAccent,
                                ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Share',
                          style: AppTypography.body(
                            c.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The picture that gets shared: dark top with the medal, rose swoop below.
class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.achievement});
  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final a = achievement;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: c.cover)),
          Positioned.fill(
            child: CustomPaint(
              painter: _SwoopPainter(c.accent, c.accentPressed),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'C',
                      style: AppTypography.title(
                        14,
                        c.onAccent,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CALESTHETICS',
                    style: AppTypography.title(
                      14,
                      c.onCover,
                      weight: FontWeight.w700,
                    ).copyWith(letterSpacing: 0.8),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: MedalBadge(
                    number: a.number,
                    unit: a.unit,
                    earned: true,
                    size: 210,
                  ),
                ),
              ),
              Text(
                a.title,
                style: AppTypography.title(
                  28,
                  Colors.white,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                a.unlockedAt == null ? '' : medalDate(a.unlockedAt!),
                style: AppTypography.body(Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 26),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwoopPainter extends CustomPainter {
  _SwoopPainter(this.a, this.b);
  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.52)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.34,
        size.width,
        size.height * 0.52,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [a, b],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_SwoopPainter old) => old.a != a || old.b != b;
}
