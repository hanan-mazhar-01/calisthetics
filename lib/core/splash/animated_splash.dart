import 'dart:io' show Platform;

import 'package:flutter/material.dart';

/// Whether the launch animation plays. Widget tests turn it off by themselves.
final bool _inTest = Platform.environment.containsKey('FLUTTER_TEST');

/// Plays [AnimatedSplash] once over [child] when the app starts.
class SplashHost extends StatefulWidget {
  const SplashHost({super.key, required this.child});
  final Widget child;

  @override
  State<SplashHost> createState() => _SplashHostState();
}

class _SplashHostState extends State<SplashHost> {
  bool _done = _inTest;

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        Positioned.fill(child: widget.child),
        if (!_done)
          Positioned.fill(
            child: AnimatedSplash(onDone: () => setState(() => _done = true)),
          ),
      ],
    );
  }
}

/// Launch animation: the rose colour opens in a circle from the middle of the
/// launch screen, the icon gets a shine, the name pops in letter by letter
/// and the tagline fades up. It starts exactly like the native launch screen
/// (same background, same rounded icon) so there is no jump.
class AnimatedSplash extends StatefulWidget {
  const AnimatedSplash({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash>
    with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 3600);
  static const _word = 'Calesthetics';

  late final AnimationController _c =
      AnimationController(vsync: this, duration: _total)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        })
        ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // 0..1 progress of the [from, to] second window.
  double _p(double from, double to, [Curve curve = Curves.linear]) {
    final t = _c.value * _total.inMilliseconds / 1000;
    return curve.transform(((t - from) / (to - from)).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cover = dark ? const Color(0xFF171516) : const Color(0xFFF7F7F7);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final size = MediaQuery.sizeOf(context);
        final reach = Offset(size.width / 2, size.height / 2).distance;
        final open = _p(0.1, 1.2, Curves.easeInOutCubic);
        final fadeOut = 1 - _p(3.1, 3.6, Curves.easeIn);
        final center = Offset(size.width / 2, size.height * 0.46);
        return Opacity(
          opacity: fadeOut,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: cover),
              CustomPaint(painter: _RosePainter(center, reach * 1.2 * open)),
              Align(
                alignment: const Alignment(0, -0.08),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _icon(),
                    const SizedBox(height: 22),
                    _name(),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: 0.85 * _p(2.2, 2.9),
                      child: const Text(
                        'STRENGTH, ONE STEP AT A TIME',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _icon() {
    const s = 120.0; // same size as the native launch icon
    final shine = _p(1.4, 2.3, Curves.easeInOut);
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(s * 0.2237),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A1428).withValues(alpha: 0.45 * _p(0.3, 1.2)),
            blurRadius: 44,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(s * 0.2237),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/app_icon.jpg', fit: BoxFit.cover),
            if (shine > 0 && shine < 1)
              Transform.translate(
                offset: Offset((shine * 2.4 - 1.2) * s, 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: const Alignment(-0.6, -0.3),
                      end: const Alignment(0.6, 0.3),
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.65),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _name() {
    final spans = <Widget>[];
    for (var i = 0; i < _word.length; i++) {
      final p = _p(1.5 + i * 0.05, 1.95 + i * 0.05, Curves.easeOutBack);
      final accent = i >= 3;
      spans.add(
        Opacity(
          opacity: p.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - p)),
            child: Transform.scale(
              scale: 0.4 + 0.6 * p,
              child: Text(
                _word[i],
                style: TextStyle(
                  fontFamily: accent ? 'Lora' : 'Poppins',
                  fontSize: 25,
                  fontWeight: accent ? FontWeight.w500 : FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: spans);
  }
}

class _RosePainter extends CustomPainter {
  _RosePainter(this.center, this.radius);
  final Offset center;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.2),
        radius: 1.1,
        colors: [Color(0xFFEE8A9B), Color(0xFFD85F70), Color(0xFFB94A5B)],
        stops: [0, 0.55, 1],
      ).createShader(rect);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RosePainter o) => o.radius != radius || o.center != center;
}
