import 'package:flutter/material.dart';

import '../../core/theme/app_colors_extension.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'glass/glass_surface.dart';

/// A single tab for [PremiumBottomNavigationBar].
class PremiumNavItem {
  const PremiumNavItem({
    required this.icon,
    required this.label,
    this.showBadge = false,
  });

  final IconData icon;
  final String label;

  /// Small notification dot on the icon's corner, for tabs like an inbox.
  final bool showBadge;
}

/// Liquid Glass tab bar: a floating pill of real frosted glass (the one
/// backdrop on screen, isolated in a [RepaintBoundary]) holding one small
/// circle per tab. The active tab widens into a pink pill that also shows
/// its label.
///
/// Tap a tab to switch, or press and drag the pink pill across the bar: it
/// tracks the finger, zooms while held, and on release glides to the nearest
/// tab and fires [onItemSelected]. The parent owns [currentIndex].
class PremiumBottomNavigationBar extends StatefulWidget {
  const PremiumBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onItemSelected,
  });

  final int currentIndex;
  final List<PremiumNavItem> items;
  final ValueChanged<int> onItemSelected;

  @override
  State<PremiumBottomNavigationBar> createState() =>
      _PremiumBottomNavigationBarState();
}

class _PremiumBottomNavigationBarState extends State<PremiumBottomNavigationBar>
    with SingleTickerProviderStateMixin {
  static const _barHeight = 64.0;
  static const _inset = 6.0;
  static const _circle = 44.0;

  /// Extra width (in slot units) the active tab gets to fit its label.
  static const _activeExtra = 1.35;
  static const _dragScale = 1.08;

  late final AnimationController _position;
  bool _dragging = false;

  int get _count => widget.items.length;

  @override
  void initState() {
    super.initState();
    _position = AnimationController(
      vsync: this,
      value: widget.currentIndex.toDouble(),
      lowerBound: 0,
      upperBound: (_count - 1).toDouble(),
      duration: AppDurations.selection,
    );
  }

  @override
  void didUpdateWidget(covariant PremiumBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex &&
        !_dragging &&
        _position.value != widget.currentIndex) {
      _position.animateTo(
        widget.currentIndex.toDouble(),
        curve: AppCurves.standard,
      );
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  /// Tab position (0 … count-1) under a pointer at [x], using even slots.
  double _positionAt(double x, double innerWidth) =>
      (x / (innerWidth / _count) - 0.5).clamp(0.0, (_count - 1).toDouble());

  void _dragTo(double x, double innerWidth) {
    _position.value = _positionAt(x, innerWidth);
  }

  void _settle() {
    if (!_dragging) return;
    setState(() => _dragging = false);
    final nearest = _position.value.round().clamp(0, _count - 1);
    _position.animateTo(
      nearest.toDouble(),
      duration: AppDurations.selection,
      curve: AppCurves.standard,
    );
    if (nearest != widget.currentIndex) widget.onItemSelected(nearest);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        // Narrower than the screen, and lifted a little off the bottom edge.
        padding: const EdgeInsets.fromLTRB(44, 0, 44, 14),
        child: RepaintBoundary(
          child: GlassSurface(
            borderRadius: BorderRadius.circular(_barHeight / 2),
            opacity: 0.7,
            child: SizedBox(
              height: _barHeight,
              child: Padding(
                padding: const EdgeInsets.all(_inset),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final inner = constraints.maxWidth;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (d) {
                        setState(() => _dragging = true);
                        _dragTo(d.localPosition.dx, inner);
                      },
                      onHorizontalDragUpdate: (d) =>
                          _dragTo(d.localPosition.dx, inner),
                      onHorizontalDragEnd: (_) => _settle(),
                      onHorizontalDragCancel: _settle,
                      child: AnimatedBuilder(
                        animation: _position,
                        builder: (context, _) => _buildTabs(context, c, inner),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, AppColorsExtension c, double inner) {
    final pos = _position.value;
    // Each tab's weight grows as the pill approaches it, so widths (and the
    // pill itself) flow continuously while gliding or dragging.
    final weights = [
      for (var i = 0; i < _count; i++)
        1 + _activeExtra * (1 - (pos - i).abs()).clamp(0.0, 1.0),
    ];
    final unit = inner / weights.fold<double>(0, (a, b) => a + b);

    var left = 0.0;
    final lefts = <double>[];
    final widths = <double>[];
    for (final w in weights) {
      lefts.add(left);
      widths.add(w * unit);
      left += w * unit;
    }

    // The pill is the blend of the two nearest slots.
    var pillLeft = 0.0, pillWidth = 0.0;
    for (var i = 0; i < _count; i++) {
      final t = (1 - (pos - i).abs()).clamp(0.0, 1.0);
      pillLeft += lefts[i] * t;
      pillWidth += widths[i] * t;
    }

    return Stack(
      children: [
        Positioned(
          left: pillLeft,
          width: pillWidth,
          top: 0,
          bottom: 0,
          child: AnimatedScale(
            scale: _dragging ? _dragScale : 1,
            duration: const Duration(milliseconds: 160),
            curve: AppCurves.overshoot,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: BorderRadius.circular(_circle),
                boxShadow: [
                  BoxShadow(
                    color: c.accent.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ),
        for (var i = 0; i < _count; i++)
          Positioned(
            left: lefts[i],
            width: widths[i],
            top: 0,
            bottom: 0,
            child: _TabCell(
              item: widget.items[i],
              // 0 = inactive circle, 1 = fully the active pill.
              activeness: (1 - (pos - i).abs()).clamp(0.0, 1.0),
              selected: i == widget.currentIndex,
              onTap: () => widget.onItemSelected(i),
            ),
          ),
      ],
    );
  }
}

class _TabCell extends StatelessWidget {
  const _TabCell({
    required this.item,
    required this.activeness,
    required this.selected,
    required this.onTap,
  });

  final PremiumNavItem item;
  final double activeness;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final iconColor = Color.lerp(c.textSecondary, c.onAccent, activeness)!;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Soft pink circle behind inactive icons; fades as the pill arrives.
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.accent.withValues(alpha: 0.16 * (1 - activeness)),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(item.icon, size: 22, color: iconColor),
                      if (item.showBadge)
                        Positioned(
                          right: 9,
                          top: 9,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: c.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: c.surface, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (activeness > 0.02)
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: activeness,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Opacity(
                          opacity: activeness * activeness,
                          child: Text(
                            item.label,
                            maxLines: 1,
                            style: AppTypography.body(
                              c.onAccent,
                              fontSize: 13,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
