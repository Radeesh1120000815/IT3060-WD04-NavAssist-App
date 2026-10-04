import 'package:go_router/go_router.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/search_screen.dart';
import 'screens/home/results_screen.dart';
import 'screens/home/route_options_screen.dart';
import 'screens/home/route_details_screen.dart';
import 'screens/home/start_navigation_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(path: '/results', builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return ResultsScreen(extra: extra);
    }),
    GoRoute(path: '/routes', builder: (context, state) => const RouteOptionsScreen()),
    GoRoute(path: '/details', builder: (context, state) => const RouteDetailsScreen()),
    GoRoute(path: '/navigate', builder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return StartNavigationScreen(destinationData: extra);
    }),
    // Member 2 will add: ...voiceRoutes,
    // Member 3 will add their own safety routes similarly
  ],
);