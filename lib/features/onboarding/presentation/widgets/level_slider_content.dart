import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/onboarding_step.dart';
import '../../../../core/haptics/haptics.dart';

/// How many of the gauge's ten blocks are lit at each slider stop (stops are
/// spread over four levels; in between the fill is interpolated).
const _fillAtStop = [3.0, 5.0, 8.0, 10.0];
const _gaugeBlocks = 10;

/// Rose at the low end, warming to coral, orange and amber at the top, so
/// the higher levels read as "fire". [t] is 0 (first level) to 1 (last).
Color _fireColor(AppColorsExtension c, double t) {
  final low = Color.alphaBlend(c.accent.withValues(alpha: 0.35), c.softRose);
  const coral = Color(0xFFEE8362);
  const orange = Color(0xFFF2A055);
  const amber = Color(0xFFF6C255);
  final stops = [low, c.accent, coral, orange, amber];
  final at = t.clamp(0.0, 1.0) * (stops.length - 1);
  final i = at.floor().clamp(0, stops.length - 2);
  return Color.lerp(stops[i], stops[i + 1], at - i)!;
}

/// A level question as a gauge + slider: a half-ring of blocks that fills as
/// the user drags, a glowing flame bubble, the level's name and description,
/// and a slider that snaps to one of the (up to four) levels. Used for
/// "What's your fitness level?".
class LevelSliderContent extends StatefulWidget {
  const LevelSliderContent({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelect,
  });

  final List<ChoiceOption> options;

  /// The saved answer, or null before one exists (then the first level is chosen).
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  State<LevelSliderContent> createState() => _LevelSliderContentState();
}

class _LevelSliderContentState extends State<LevelSliderContent>
    with TickerProviderStateMixin {
  late final AnimationController _snap;
  late final AnimationController _loop;
  double _pos = 0; // 0 … options.length - 1, continuous while dragging
  double _from = 0;
  double _to = 0;
  bool _dragging = false;

  int get _last => widget.options.length - 1;
  int get _nearest => _pos.round().clamp(0, _last);

  @override
  void initState() {
    super.initState();
    _snap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(_onSnapTick);
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    final i = widget.options.indexWhere((o) => o.id == widget.selectedId);
    _pos = (i < 0 ? 0 : i).toDouble();
    if (i < 0) {
      // No answer yet: start on the first level, like the reference.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSelect(widget.options.first.id);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void didUpdateWidget(LevelSliderContent old) {
    super.didUpdateWidget(old);
    final i = widget.options.indexWhere((o) => o.id == widget.selectedId);
    if (!_dragging && i >= 0 && i != _nearest) _animateTo(i);
  }

  @override
  void dispose() {
    _snap.dispose();
    _loop.dispose();
    super.dispose();
  }

  void _onSnapTick() {
    setState(
      () => _pos =
          _from + (_to - _from) * Curves.easeOutBack.transform(_snap.value),
    );
  }

  void _animateTo(int index) {
    _from = _pos;
    _to = index.toDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _pos = _to);
      return;
    }
    _snap.forward(from: 0);
  }

  /// Moves the thumb to [value] while dragging and reports level changes live.
  void _drag(double value) {
    final before = _nearest;
    setState(() => _pos = value.clamp(0, _last.toDouble()));
    if (_nearest != before) {
      Haptics.light();
      widget.onSelect(widget.options[_nearest].id);
    }
  }

  void _release() {
    // A plain tap also "cancels" the drag recognizer; ignore that unless a
    // drag actually started, or the thumb would be pulled back to where it was.
    if (!_dragging) return;
    _dragging = false;
    final target = _nearest;
    _animateTo(target);
    widget.onSelect(widget.options[target].id);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final option = widget.options[_nearest];
    final fill = _interp(_pos);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              final outer = w * 0.42;
              final bubble = w * 0.36;
              final height = outer + bubble / 2 + 6;
              return SizedBox(
                width: w,
                height: height,
                child: AnimatedBuilder(
                  animation: _loop,
                  builder: (context, _) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _GaugePainter(
                            fill: fill,
                            outer: outer,
                            thickness: w * 0.085,
                            colors: c,
                          ),
                        ),
                      ),
                      Positioned(
                        left: w / 2 - bubble / 2,
                        top: outer - bubble / 2 + 4,
                        width: bubble,
                        height: bubble,
                        child: _FlameBubble(
                          size: bubble,
                          level: _pos / math.max(_last, 1),
                          twinkle: _loop.value,
                          colors: c,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(option.id),
              children: [
                Text(
                  option.label,
                  textAlign: TextAlign.center,
                  style: AppTypography.title(
                    30,
                    c.textPrimary,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 70,
                  child: Text(
                    option.description ?? '',
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: AppTypography.body(
                      c.textSecondary,
                      fontSize: 17,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _SliderCard(
            levels: widget.options.length,
            pos: _pos,
            firstLabel: widget.options.first.label,
            lastLabel: widget.options.last.label,
            onDragStart: () {
              _dragging = true;
              _snap.stop();
            },
            onDrag: _drag,
            onRelease: _release,
            onTapLevel: (i) {
              if (i != _nearest) Haptics.light();
              _dragging = false;
              _animateTo(i);
              widget.onSelect(widget.options[i].id);
            },
          ),
        ],
      ),
    );
  }

  /// Number of lit gauge blocks at slider position [pos], interpolated.
  double _interp(double pos) {
    final stops = widget.options.length == _fillAtStop.length
        ? _fillAtStop
        : [
            for (var i = 0; i < widget.options.length; i++)
              _gaugeBlocks * (i + 1) / widget.options.length,
          ];
    final lo = pos.floor().clamp(0, stops.length - 1);
    final hi = (lo + 1).clamp(0, stops.length - 1);
    return stops[lo] + (stops[hi] - stops[lo]) * (pos - lo);
  }
}

/// The half-ring of ten blocks, lighter on the left and deeper on the right.
class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.fill,
    required this.outer,
    required this.thickness,
    required this.colors,
  });

  final double fill;
  final double outer;
  final double thickness;
  final AppColorsExtension colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, outer + 4);
    const gap = 0.05;
    final step = math.pi / _gaugeBlocks;
    final inner = outer - thickness;
    // Opaque on purpose: the fill and the corner-softening stroke overlap, and
    // a translucent colour would show a darker rim where they do.
    final pale = Color.alphaBlend(
      colors.softRose.withValues(alpha: 0.4),
      colors.background,
    );

    for (var i = 0; i < _gaugeBlocks; i++) {
      final a0 = math.pi + gap / 2 + i * step;
      final sweep = step - gap;
      final amount = (fill - i).clamp(0.0, 1.0);
      final lit = _fireColor(colors, i / (_gaugeBlocks - 1));
      final color = Color.lerp(pale, lit, Curves.easeOut.transform(amount))!;

      final path = Path()
        ..arcTo(Rect.fromCircle(center: center, radius: outer), a0, sweep, true)
        ..arcTo(
          Rect.fromCircle(center: center, radius: inner),
          a0 + sweep,
          -sweep,
          false,
        )
        ..close();
      final paint = Paint()..color = color;
      canvas.drawPath(path, paint);
      // A thin same-colour stroke softens the block corners.
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fill != fill ||
      old.outer != outer ||
      old.thickness != thickness ||
      old.colors != colors;
}

/// Soft glass-looking bubble with a flame that glows brighter with the level.
class _FlameBubble extends StatelessWidget {
  const _FlameBubble({
    required this.size,
    required this.level,
    required this.twinkle,
    required this.colors,
  });

  final double size;
  final double level; // 0–1
  final double twinkle; // 0–1 looping
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) {
    final glow = 0.18 + 0.22 * level;
    final warm = _fireColor(colors, level);
    final warmer = _fireColor(colors, (level + 0.3).clamp(0.0, 1.0));
    double blink(double phase) =>
        0.35 + 0.65 * (0.5 + 0.5 * math.sin(twinkle * 2 * math.pi + phase));
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colors.surface.withValues(alpha: 0.98),
            Color.alphaBlend(
              colors.softRose.withValues(alpha: 0.55),
              colors.surface,
            ),
          ],
        ),
        border: Border.all(color: colors.surface, width: 2),
        boxShadow: [
          BoxShadow(
            color: warm.withValues(alpha: glow),
            blurRadius: 34,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ShaderMask(
            shaderCallback: (rect) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [warm, warmer],
            ).createShader(rect),
            child: Icon(
              Icons.local_fire_department_rounded,
              size: size * 0.52,
              color: Colors.white,
            ),
          ),
          Positioned(
            left: size * 0.16,
            top: size * 0.22,
            child: Opacity(
              opacity: blink(0),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: size * 0.14,
                color: warm.withValues(alpha: 0.7),
              ),
            ),
          ),
          Positioned(
            right: size * 0.12,
            top: size * 0.42,
            child: Opacity(
              opacity: blink(2.4),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: size * 0.2,
                color: warm.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.levels,
    required this.pos,
    required this.firstLabel,
    required this.lastLabel,
    required this.onDragStart,
    required this.onDrag,
    required this.onRelease,
    required this.onTapLevel,
  });

  final int levels;
  final double pos;
  final String firstLabel;
  final String lastLabel;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDrag;
  final VoidCallback onRelease;
  final ValueChanged<int> onTapLevel;

  static const _thumb = 42.0;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: c.accent.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              final usable = w - _thumb;
              double x(double p) => _thumb / 2 + usable * (p / (levels - 1));
              double valueAt(double dx) =>
                  ((dx - _thumb / 2) / usable * (levels - 1)).clamp(
                    0.0,
                    levels - 1.0,
                  );
              final thumbX = x(pos);
              return Semantics(
                slider: true,
                label: 'Level',
                value: '${pos.round() + 1} of $levels',
                increasedValue:
                    '${(pos.round() + 2).clamp(1, levels)} of $levels',
                decreasedValue: '${pos.round().clamp(1, levels)} of $levels',
                onIncrease: () =>
                    onTapLevel((pos.round() + 1).clamp(0, levels - 1)),
                onDecrease: () =>
                    onTapLevel((pos.round() - 1).clamp(0, levels - 1)),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) =>
                      onTapLevel(valueAt(d.localPosition.dx).round()),
                  onHorizontalDragStart: (d) {
                    onDragStart();
                    onDrag(valueAt(d.localPosition.dx));
                  },
                  onHorizontalDragUpdate: (d) =>
                      onDrag(valueAt(d.localPosition.dx)),
                  onHorizontalDragEnd: (_) => onRelease(),
                  onHorizontalDragCancel: onRelease,
                  child: SizedBox(
                    height: 52,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 9,
                          height: 34,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: c.surfaceMuted,
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 9,
                          height: 34,
                          width: pos < 0.02 ? 0 : thumbX + 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(17),
                              // The fill warms up the further the thumb goes.
                              gradient: LinearGradient(
                                colors: [
                                  _fireColor(c, 0.15),
                                  _fireColor(
                                    c,
                                    0.15 + 0.85 * (pos / (levels - 1)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        for (var i = 0; i < levels; i++)
                          Positioned(
                            left: x(i.toDouble()) - 4,
                            top: 22,
                            width: 8,
                            height: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i < pos - 0.01
                                    ? c.onAccent.withValues(alpha: 0.9)
                                    : c.textMuted.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        Positioned(
                          left: thumbX - _thumb / 2,
                          top: 5,
                          width: _thumb,
                          height: _thumb,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.surface,
                              border: Border.all(
                                color: _fireColor(
                                  c,
                                  0.15 + 0.85 * (pos / (levels - 1)),
                                ),
                                width: 5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _fireColor(
                                    c,
                                    pos / (levels - 1),
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tapping an end label jumps to that level.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTapLevel(0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    firstLabel,
                    style: AppTypography.body(c.textSecondary, fontSize: 16),
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTapLevel(levels - 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    lastLabel,
                    style: AppTypography.body(c.textSecondary, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
