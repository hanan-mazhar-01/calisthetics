import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/exercises/presentation/screens/exercise_detail_screen.dart';
import '../../features/onboarding/presentation/providers/onboarding_completed_provider.dart';
import '../../features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import '../../features/paywall/presentation/screens/paywall_screen.dart';
import '../../features/plan/presentation/screens/day_overview_screen.dart';
import '../../features/plan/presentation/screens/plan_settings_screen.dart';
import '../../features/profile/presentation/screens/favorites_screen.dart';
import '../../features/profile/presentation/screens/history_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/workout/domain/workout_request.dart';
import '../../features/workout/presentation/screens/workout_screen.dart';
import 'app_shell.dart';

const _onboardingPath = '/';
const _homePath = '/home';

/// Routes anyone may open, finished onboarding or not.
const _publicPaths = {'/paywall'};

/// Centralized route table. Onboarding and the workout player manage their
/// own internal step/phase state rather than pushing a route per step.
///
/// The redirect keeps the two worlds apart: finished users never see
/// onboarding again, unfinished users can't reach the main app.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: _onboardingPath,
    redirect: (context, state) {
      final completed = ref.read(onboardingCompletedProvider);
      final location = state.matchedLocation;
      if (_publicPaths.contains(location)) return null;
      final atOnboarding = location == _onboardingPath;
      if (completed && atOnboarding) return _homePath;
      if (!completed && !atOnboarding) return _onboardingPath;
      return null;
    },
    routes: [
      GoRoute(
        path: _onboardingPath,
        builder: (context, state) => const OnboardingFlowScreen(),
      ),
      GoRoute(path: _homePath, builder: (context, state) => const AppShell()),
      GoRoute(
        path: '/day/:weekday',
        builder: (context, state) => DayOverviewScreen(
          weekday: int.parse(state.pathParameters['weekday']!),
          week: int.tryParse(state.uri.queryParameters['week'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/exercise/:number',
        builder: (context, state) => ExerciseDetailScreen(
          number: int.parse(state.pathParameters['number']!),
        ),
      ),
      GoRoute(
        path: '/workout',
        builder: (context, state) =>
            WorkoutScreen(request: state.extra! as WorkoutRequest),
      ),
      GoRoute(
        path: '/plan-settings',
        builder: (context, state) => const PlanSettingsScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
    ],
  );
});
