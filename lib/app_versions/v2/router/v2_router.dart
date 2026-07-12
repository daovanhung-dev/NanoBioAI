import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/router/router.dart';
import 'package:nano_app/app_versions/v2/features/auth/auth.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/cloud_sync.dart';
import 'package:nano_app/app_versions/v2/features/health_scoring/health_scoring.dart';
import 'package:nano_app/app_versions/v2/features/home/presentation/pages/v2_home_page.dart';
import 'package:nano_app/app_versions/v2/features/payments/payments.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/sale_referral/presentation/pages/sale_shell_page.dart';

final v2Routes = <RouteBase>[
  GoRoute(
    path: V2RoutePaths.authGate,
    name: V2RoutePaths.authGate,
    builder: (context, state) => const AuthGatePage(),
  ),
  GoRoute(
    path: V2RoutePaths.login,
    name: V2RoutePaths.login,
    builder: (context, state) => const V2LoginPage(),
  ),
  GoRoute(
    path: V2RoutePaths.register,
    name: V2RoutePaths.register,
    builder: (context, state) => const V2RegisterPage(),
  ),
  GoRoute(
    path: V2RoutePaths.verifyEmail,
    name: V2RoutePaths.verifyEmail,
    builder: (context, state) {
      return V2VerifyEmailPage(email: state.uri.queryParameters['email'] ?? '');
    },
  ),
  GoRoute(
    path: V2RoutePaths.forgotPassword,
    name: V2RoutePaths.forgotPassword,
    builder: (context, state) => const V2ForgotPasswordPage(),
  ),
  GoRoute(
    path: V2RoutePaths.resetPassword,
    name: V2RoutePaths.resetPassword,
    builder: (context, state) => const V2ResetPasswordPage(),
  ),
  GoRoute(
    path: V2RoutePaths.authCallback,
    name: V2RoutePaths.authCallback,
    builder: (context, state) {
      final rawUri = state.uri.queryParameters['uri'];
      return V2AuthCallbackPage(
        uri: rawUri == null ? state.uri : Uri.tryParse(rawUri) ?? state.uri,
      );
    },
  ),
  GoRoute(
    path: V2RoutePaths.sale,
    name: V2RoutePaths.sale,
    builder: (context, state) => const SaleShellPage(),
  ),
  GoRoute(
    path: V2RoutePaths.healthScore,
    name: V2RoutePaths.healthScore,
    builder: (context, state) => const HealthScoreHabitsPage(),
  ),
  GoRoute(
    path: V2RoutePaths.payments,
    name: V2RoutePaths.payments,
    builder: (context, state) => const MembershipPaymentPage(),
  ),
  GoRoute(
    path: V2RoutePaths.home,
    name: V2RoutePaths.home,
    builder: (context, state) => const V2HomePage(),
  ),
];

final v2RouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier();
  ref.listen(v2AuthControllerProvider, (_, __) => refresh.refresh());
  ref.listen(userDataSyncControllerProvider, (_, __) => refresh.refresh());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: V1RoutePaths.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      final auth = ref.read(v2AuthControllerProvider);
      final routeState = auth.asData?.value;
      final syncState = ref.read(userDataSyncControllerProvider);
      final isAccountEntry =
          path == V2RoutePaths.login || path == V2RoutePaths.register;
      final isProtected = _protectedPaths.contains(path);

      if (isAccountEntry &&
          routeState != null &&
          routeState.status != AuthRouteStatus.unauthenticated) {
        return V2RoutePaths.authGate;
      }

      if (!isProtected) return null;
      if (syncState.status == UserDataSyncStatus.awaitingConsent ||
          syncState.status == UserDataSyncStatus.syncing) {
        return V2RoutePaths.authGate;
      }
      if (auth.isLoading) return V2RoutePaths.authGate;
      if (auth.hasError || routeState == null) return V2RoutePaths.authGate;

      return switch (routeState.status) {
        AuthRouteStatus.authenticatedReady => null,
        AuthRouteStatus.unauthenticated => V2RoutePaths.login,
        _ => V2RoutePaths.authGate,
      };
    },
    routes: [...v1Routes, ...v2Routes],
  );
});

const _protectedPaths = <String>{
  V2RoutePaths.home,
  V2RoutePaths.healthScore,
  V2RoutePaths.payments,
  V2RoutePaths.sale,
};

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
