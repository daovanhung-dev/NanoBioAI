import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/features/auth/auth.dart';
import 'package:nano_app/features/dashboard/dashboard.dart';
import 'package:nano_app/features/onboarding/onboarding.dart';
import 'package:nano_app/features/splash/splash.dart';

import 'route_guards.dart';
import '../constants/routes/route_names.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.splash,

  routes: [
    /// Splash
    GoRoute(
      path: RoutePaths.splash,
      name: RoutePaths.splash,
      builder: (context, state) => SplashPage(),
    ),

    /// Login
    GoRoute(
      path: RoutePaths.login,
      name: RoutePaths.login,
      redirect: RouteGuards.guestGuard,
      builder: (context, state) => const LoginPage(),
    ),

    /// Register
    GoRoute(
      path: RoutePaths.register,
      name: RoutePaths.register,
      builder: (context, state) => const Placeholder(),
    ),

    /// Dashboard
    GoRoute(
      path: RoutePaths.dashboard,
      name: RoutePaths.dashboard,
      // redirect: RouteGuards.authGuard,
      builder: (context, state) => const DashboardPage(),
    ),

    /// Onboarding
    GoRoute(
      path: RoutePaths.onboarding,
      name: RoutePaths.onboarding,
      builder: (context, state) => const OnboardingPage(),
    ),

    /// AI Chat
    GoRoute(
      path: RoutePaths.aiChat,
      name: RoutePaths.aiChat,
      redirect: RouteGuards.authGuard,
      builder: (context, state) => const Placeholder(),
    ),

    /// Nutrition
    GoRoute(
      path: RoutePaths.nutrition,
      name: RoutePaths.nutrition,
      redirect: RouteGuards.authGuard,
      builder: (context, state) => const Placeholder(),
    ),

    /// Profile
    GoRoute(
      path: RoutePaths.profile,
      name: RoutePaths.profile,
      redirect: RouteGuards.authGuard,
      builder: (context, state) => const Placeholder(),
    ),
  ],
);
