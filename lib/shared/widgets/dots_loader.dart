import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Three dots that rise and fall one after another: the wait indicator for a
/// button whose action is under way. Stands still when animations are off.
class DotsLoader extends StatefulWidget {
  const DotsLoader({super.key, required this.color, this.dot = 7});

  final Color color;

  /// Diameter of one dot.
  final double dot;

  @override
  State<DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<DotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dot;
    return Semantics(
      label: 'Loading',
      excludeSemantics: true,
      child: SizedBox(
        height: d * 2.2,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) SizedBox(width: d * 0.7),
                _dot(_phase(i)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 0 (resting) to 1 (top of its hop) for dot [i].
  double _phase(int i) {
    if (!_c.isAnimating) return 0.4;
    final t = (_c.value - i * 0.16) % 1.0;
    return t < 0.5 ? math.sin(t * 2 * math.pi) : 0;
  }

  Widget _dot(double lift) {
    final d = widget.dot;
    return Transform.translate(
      offset: Offset(0, -d * 0.7 * lift),
      child: Opacity(
        opacity: 0.45 + 0.55 * lift,
        child: Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
