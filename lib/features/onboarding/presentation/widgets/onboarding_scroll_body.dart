import 'package:flutter/material.dart';

import 'onboarding_viewport.dart';

/// Scrolls [header] and [content] as one page. When [fillsHeight] is set the
/// content is told how much room is left below the header
/// ([OnboardingViewport]) so list cards can grow to fill the screen, and the
/// page still scrolls if they don't fit.
class OnboardingScrollBody extends StatefulWidget {
  const OnboardingScrollBody({
    super.key,
    required this.header,
    required this.content,
    required this.fillsHeight,
  });

  final Widget header;
  final Widget content;
  final bool fillsHeight;

  @override
  State<OnboardingScrollBody> createState() => _OnboardingScrollBodyState();
}

class _OnboardingScrollBodyState extends State<OnboardingScrollBody> {
  final _headerKey = GlobalKey();

  /// Rough height until the real one is measured, to avoid a visible jump.
  double _headerHeight = 150;

  void _measure() {
    final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    if ((box.size.height - _headerHeight).abs() > 0.5) {
      setState(() => _headerHeight = box.size.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measure();
    });
    return LayoutBuilder(
      builder: (context, constraints) {
        final below = (constraints.maxHeight - _headerHeight).clamp(
          0.0,
          double.infinity,
        );
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyedSubtree(key: _headerKey, child: widget.header),
              if (widget.fillsHeight)
                OnboardingViewport(
                  availableHeight: below,
                  child: widget.content,
                )
              else
                widget.content,
            ],
          ),
        );
      },
    );
  }
}
