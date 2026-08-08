import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/app_versions/v2/features/auth/auth.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/app_versions/v3/features/advanced_tracking/advanced_tracking.dart';
import 'package:nano_app/app_versions/v3/features/familyplus/familyplus.dart';
import 'package:nano_app/app_versions/v3/features/home/presentation/pages/v3_home_page.dart';
import 'package:nano_app/app_versions/v3/router/v3_route_paths.dart';

final v3Routes = <RouteBase>[
  GoRoute(
    path: V3RoutePaths.home,
    name: V3RoutePaths.home,
    builder: (context, state) => const V3HomePage(),
  ),
  GoRoute(
    path: V3RoutePaths.advancedTracking,
    name: V3RoutePaths.advancedTracking,
    builder: (context, state) => const AdvancedTrackingPage(),
  ),
  GoRoute(
    path: V3RoutePaths.familyPlus,
    name: V3RoutePaths.familyPlus,
    builder: (context, state) => const FamilyPlusPage(),
  ),
];

final v3StandaloneRoutes = <RouteBase>[
  ...v3Routes,
  GoRoute(
    path: V2RoutePaths.login,
    name: V2RoutePaths.login,
    builder: (context, state) => const V2LoginPage(),
  ),
  GoRoute(
    path: V1RoutePaths.lifestyleSchedule,
    name: V1RoutePaths.lifestyleSchedule,
    builder: (context, state) =>
        LifestyleSchedulePage(initialItemId: state.uri.queryParameters['item']),
  ),
];

final v3Router = GoRouter(
  initialLocation: V3RoutePaths.home,
  routes: v3StandaloneRoutes,
);
