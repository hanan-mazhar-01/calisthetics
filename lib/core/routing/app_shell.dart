import 'package:flutter/material.dart';

import '../../features/discover/presentation/screens/discover_screen.dart';
import '../../features/plan/presentation/screens/plan_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../shared/widgets/glass/app_background.dart';
import '../../shared/widgets/nav_icons.dart';
import '../../shared/widgets/premium_bottom_nav.dart';

const appTabs = [
  PremiumNavItem(kind: NavIconKind.plan, label: 'Plan'),
  PremiumNavItem(kind: NavIconKind.discover, label: 'Discover'),
  PremiumNavItem(kind: NavIconKind.progress, label: 'Progress'),
  PremiumNavItem(kind: NavIconKind.profile, label: 'Profile'),
];

/// Authenticated app shell: four tabs (Plan · Discover · Progress · Profile)
/// over an [IndexedStack] so each keeps its scroll position. The
/// glass tab bar floats over the content (`extendBody`), so tab screens read
/// `MediaQuery.padding.bottom` to keep their last item clear of it.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: IndexedStack(
          index: _index,
          children: const [
            PlanScreen(),
            DiscoverScreen(),
            ProgressScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: PremiumBottomNavigationBar(
          currentIndex: _index,
          items: appTabs,
          onItemSelected: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
