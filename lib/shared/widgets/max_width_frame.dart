import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Keeps the app phone-shaped on wide screens (tablets, landscape).
///
/// The screens are designed for phone widths; stretched across an iPad they
/// become wide, sparse rows and full-width buttons. Above [maxWidth] the app
/// is drawn in a centred column of that width on the theme's background, and
/// [MediaQuery] reports the column's width, so screens that size themselves
/// from the screen width lay out as they would on a large phone. Phones
/// (narrower than [maxWidth]) are passed through untouched.
class MaxWidthFrame extends StatelessWidget {
  const MaxWidthFrame({super.key, required this.child, this.maxWidth = 640});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width <= maxWidth) return child;
    final width = math.min(mq.size.width, maxWidth);
    // The side insets (notch/cut-out in landscape) fall outside the column.
    EdgeInsets inner(EdgeInsets e) => e.copyWith(left: 0, right: 0);
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: SizedBox(
          width: width,
          child: MediaQuery(
            data: mq.copyWith(
              size: Size(width, mq.size.height),
              padding: inner(mq.padding),
              viewPadding: inner(mq.viewPadding),
              viewInsets: inner(mq.viewInsets),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
