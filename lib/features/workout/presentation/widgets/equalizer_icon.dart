import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Four little bars that dance while music plays and rest flat when it
/// doesn't (or when animations are turned off).
class EqualizerIcon extends StatefulWidget {
  const EqualizerIcon({
    super.key,
    required this.active,
    required this.color,
    this.size = 20,
  });

  final bool active;
  final Color color;
  final double size;

  @override
  State<EqualizerIcon> createState() => _EqualizerIconState();
}

class _EqualizerIconState extends State<EqualizerIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  void _sync() {
    final run = widget.active && !MediaQuery.disableAnimationsOf(context);
    if (run && !_c.isAnimating) {
      _c.repeat();
    } else if (!run && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(EqualizerIcon old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  width: s * 0.16,
                  height: s * _height(i),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(s),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// 0.25 (flat) to 1 (full) for bar [i].
  double _height(int i) {
    if (!widget.active) return const [0.35, 0.55, 0.3, 0.45][i];
    const phase = [0.0, 1.7, 3.1, 4.6];
    const speed = [1.0, 2.0, 1.0, 3.0]; // whole numbers: the loop is seamless
    final t = _c.value * 2 * math.pi;
    return 0.3 + 0.7 * (0.5 + 0.5 * math.sin(t * speed[i] + phase[i]));
  }
}
