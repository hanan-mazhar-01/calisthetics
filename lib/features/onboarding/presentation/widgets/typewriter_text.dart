import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'intro_motion.dart';

/// A run of text drawn in [style] (the base style when null).
class TypeSegment {
  const TypeSegment(this.text, [this.style]);

  final String text;
  final TextStyle? style;
}

/// Types its [segments] out character by character, with a light haptic tick
/// as it goes, then calls [onDone].
///
/// Layout never jumps: the text that has not been typed yet is laid out
/// transparent, so line breaks are final from the first frame. With
/// "reduce motion" on, the full text shows at once (no ticks).
class TypewriterText extends StatefulWidget {
  const TypewriterText({
    super.key,
    required this.segments,
    required this.style,
    this.onDone,
    this.delay = const Duration(milliseconds: 120),
    this.millisPerChar = 28,
    this.haptics = true,
  });

  final List<TypeSegment> segments;
  final TextStyle style;
  final VoidCallback? onDone;
  final Duration delay;
  final int millisPerChar;
  final bool haptics;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final int _total;
  late final int _typingMs;
  int _shown = 0;
  int _ticks = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _total = widget.segments.fold(0, (n, s) => n + s.text.length);
    _typingMs = (_total * widget.millisPerChar).clamp(450, 1300);
    // One clock for the short pause before typing starts and the typing
    // itself (no Timer, so nothing is left pending if the screen goes away).
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.delay.inMilliseconds + _typingMs),
    )..addListener(_onTick);
    _controller.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone?.call();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context) || _total == 0) {
      _shown = _total;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onDone?.call();
      });
      return;
    }
    _controller.forward();
  }

  void _onTick() {
    final elapsed =
        _controller.value * _controller.duration!.inMilliseconds -
        widget.delay.inMilliseconds;
    final next = (elapsed / _typingMs * _total).floor().clamp(0, _total);
    if (next == _shown) return;
    if (widget.haptics) {
      final all = widget.segments.map((s) => s.text).join();
      for (var i = _shown; i < next && i < all.length; i++) {
        if (all[i].trim().isEmpty) continue;
        // A tick on every second letter: felt as typing, not as a buzz.
        if (_ticks++ % 2 == 0) HapticFeedback.selectionClick();
      }
    }
    setState(() => _shown = next);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    var left = _shown;
    for (final s in widget.segments) {
      final style = widget.style.merge(s.style);
      final visible = left.clamp(0, s.text.length);
      left -= visible;
      if (visible > 0) {
        spans.add(TextSpan(text: s.text.substring(0, visible), style: style));
      }
      if (visible < s.text.length) {
        spans.add(
          TextSpan(
            text: s.text.substring(visible),
            style: style.merge(const TextStyle(color: Colors.transparent)),
          ),
        );
      }
    }
    final full = widget.segments.map((s) => s.text).join();
    return Semantics(
      label: full,
      child: ExcludeSemantics(
        child: RichText(
          text: TextSpan(style: widget.style, children: spans),
        ),
      ),
    );
  }
}

/// Shares the "headline has finished typing" clock with the content below
/// it, so options and cards can appear one after another right after.
class StepIntroScope extends InheritedWidget {
  const StepIntroScope({
    super.key,
    required this.animation,
    required super.child,
  });

  /// 0 to 1, starts when the headline is typed.
  final Animation<double> animation;

  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StepIntroScope>()?.animation;

  @override
  bool updateShouldNotify(StepIntroScope old) => animation != old.animation;
}

/// Fades and slides [child] in after the headline, [index] places down the
/// stagger. Without a [StepIntroScope] it simply shows.
class StepReveal extends StatelessWidget {
  const StepReveal({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = StepIntroScope.maybeOf(context);
    if (animation == null) return child;
    final start = (index * 0.08).clamp(0.0, 0.5);
    return IntroReveal(
      animation: animation,
      from: start,
      to: start + 0.5,
      slide: const Offset(0, 22),
      child: child,
    );
  }
}
