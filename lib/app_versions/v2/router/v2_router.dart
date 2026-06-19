import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/app_versions/v1/router/v1_router.dart';
import 'package:nano_app/app_versions/v2/features/home/presentation/pages/v2_home_page.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';

final v2Routes = <RouteBase>[
  GoRoute(
    path: V2RoutePaths.home,
    name: V2RoutePaths.home,
    builder: (context, state) => const V2HomePage(),
  ),
];

final v2Router = GoRouter(
  initialLocation: V1RoutePaths.splash,
  routes: [...v1Routes, ...v2Routes],
);
