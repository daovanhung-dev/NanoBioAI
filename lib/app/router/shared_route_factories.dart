import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/app_versions/v2/features/auth/auth.dart';
import 'package:nano_app/app_versions/v2/features/payments/payments.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/membership/membership_upgrade_route.dart';

/// Canonical route factories shared by the unified and standalone routers.
/// Keeping one builder for each route prevents behavior/query parsing from
/// drifting between V1/V2/V3 router compositions.
GoRoute buildLifestyleScheduleRoute() {
  return GoRoute(
    path: V1RoutePaths.lifestyleSchedule,
    name: V1RoutePaths.lifestyleSchedule,
    builder: (context, state) =>
        LifestyleSchedulePage(initialItemId: state.uri.queryParameters['item']),
  );
}

GoRoute buildV2LoginRoute() {
  return GoRoute(
    path: V2RoutePaths.login,
    name: V2RoutePaths.login,
    builder: (context, state) => const V2LoginPage(),
  );
}

GoRoute buildMembershipPaymentRoute() {
  return GoRoute(
    path: V2RoutePaths.payments,
    name: V2RoutePaths.payments,
    builder: (context, state) => MembershipPaymentPage(
      initialPlanCode: normalizeMembershipUpgradePlan(
        state.uri.queryParameters['plan'],
      ),
    ),
  );
}
