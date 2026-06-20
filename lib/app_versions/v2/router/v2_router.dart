import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/router/router.dart';
import 'package:nano_app/app_versions/v1/router/v1_router.dart';
import 'package:nano_app/app_versions/v2/features/auth/auth.dart';
import 'package:nano_app/app_versions/v2/features/home/presentation/pages/v2_home_page.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';

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
    builder: (context, state) => V2AuthCallbackPage(uri: state.uri),
  ),
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
