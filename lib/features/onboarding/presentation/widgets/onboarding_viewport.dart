import 'package:flutter/widgets.dart';

/// How much height is left for a fill-the-screen list below the headline.
class OnboardingViewport extends InheritedWidget {
  const OnboardingViewport({
    super.key,
    required this.availableHeight,
    required super.child,
  });

  final double availableHeight;

  static double? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<OnboardingViewport>()
      ?.availableHeight;

  @override
  bool updateShouldNotify(OnboardingViewport old) =>
      old.availableHeight != availableHeight;
}
