import 'package:flutter/material.dart';

import '../../../core/theme/app_colors_extension.dart';

/// The flat page background every main-app screen sits on. Wrap a screen
/// body in it (or use [GradientScaffold]).
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Flat, solid page colour: no gradient, no blur.
    return ColoredBox(color: context.appColors.background, child: child);
  }
}

/// A `Scaffold` on the shared flat background.
class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.extendBody = false,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: extendBody,
        appBar: appBar,
        bottomNavigationBar: bottomNavigationBar,
        body: body,
      ),
    );
  }
}
