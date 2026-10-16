import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/glass/app_background.dart';
import '../widgets/paywall_content.dart';

/// Premium intro and free-vs-premium on one screen. The X returns to where
/// the user came from, or to Home when opened directly; either way she stays
/// on the free tier.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
        child: PaywallContent(
          onClose: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
    );
  }
}
