import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/features/splash/presentation/pages/splash_page.dart';

import 'route_guards.dart';
import '../constants/routes/route_names.dart';
import 'route_paths.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.splash,

  routes: [

    /// Splash
    GoRoute(
      path: RoutePaths.splash,
      name: RouteNames.splash,
      builder: (context, state) => SplashPage(),
    ),

    /// Login
    GoRoute(
      path: RoutePaths.login,
      name: RouteNames.login,
      redirect: RouteGuards.guestGuard,
      builder: (context, state) => const Placeholder(),
    ),

    /// Register
    GoRoute(
      path: RoutePaths.register,
      name: RouteNames.register,
      builder: (context, state) => const Placeholder(),
    ),

    /// Dashboard
    GoRoute(
      path: RoutePaths.dashboard,
      name: RouteNames.dashboard,
      redirect: RouteGuards.authGuard,
      builder: (context, state) => const Placeholder(),
    ),

    /// AI Chat
    GoRoute(
      path: RoutePaths.aiChat,
      name: RouteNames.aiChat,
      redirect: RouteGuards.authGuard,
      builder: (context, state) => const Placeholder(),
    ),

    /// Nutrition
    GoRoute(
      path: RoutePaths.nutrition,
      name: RouteNames.nutrition,
      redirect: RouteGuards.authGuard,
      builder: (context, state) => const Placeholder(),
    ),

    /// Profile
    GoRoute(
      path: RoutePaths.profile,
      name: RouteNames.profile,
      redirect: RouteGuards.authGuard,
      builder: (context, state) => const Placeholder(),
    ),
  ],
);
