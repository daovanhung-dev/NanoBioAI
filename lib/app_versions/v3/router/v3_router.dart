import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v2/router/v2_router.dart';
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

final v3Router = GoRouter(
  initialLocation: V3RoutePaths.home,
  routes: [...v2Routes, ...v3Routes],
);
