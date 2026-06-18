import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/features/auth/auth.dart';
import 'package:nano_app/features/dashboard/dashboard.dart';
import 'package:nano_app/features/dashboard/presentation/pages/menu_page.dart';
import 'package:nano_app/features/daily_health_tracking/presentation/pages/daily_health_tracking_page.dart';
import 'package:nano_app/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart';
import 'package:nano_app/features/meal_plan/presentation/pages/meal_plan_page.dart';
import 'package:nano_app/features/nutrition/presentation/pages/nutrition_page.dart';
import 'package:nano_app/features/onboarding/onboarding.dart';
import 'package:nano_app/features/profile/presentation/pages/profile_page.dart';
import 'package:nano_app/features/splash/splash.dart';
import 'package:nano_app/features/ai_chat/presentation/ai_chat_screen.dart';
import 'package:nano_app/features/community/presentation/pages/community_page.dart';
import 'package:nano_app/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart';
import 'package:nano_app/features/stress_tracking/presentation/pages/stress_tracking_page.dart';

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

    /// Menu
    GoRoute(
      path: RoutePaths.menu,
      name: RoutePaths.menu,
      builder: (context, state) => const MainNavigationPage(),
    ),

    /// Meal Plan
    GoRoute(
      path: RoutePaths.mealPlan,
      name: RoutePaths.mealPlan,
      builder: (context, state) => const MealPlanPage(),
    ),

    /// Daily Health Tracking
    GoRoute(
      path: RoutePaths.healthTracking,
      name: RoutePaths.healthTracking,
      builder: (context, state) => const DailyHealthTrackingPage(),
    ),

    /// Lifestyle Schedule
    GoRoute(
      path: RoutePaths.lifestyleSchedule,
      name: RoutePaths.lifestyleSchedule,
      builder: (context, state) => const LifestyleSchedulePage(),
    ),

    /// Sleep Tracking
    GoRoute(
      path: RoutePaths.sleepTracking,
      name: RoutePaths.sleepTracking,
      builder: (context, state) => const SleepTrackingPage(),
    ),

    /// Stress Tracking
    GoRoute(
      path: RoutePaths.stressTracking,
      name: RoutePaths.stressTracking,
      builder: (context, state) => const StressTrackingPage(),
    ),

    /// AI Chat
    GoRoute(
      path: RoutePaths.aiChat,
      name: RoutePaths.aiChat,
      redirect: RouteGuards.authGuard,
      builder: (context, state) => const AIChatScreen(),
    ),

    /// Nutrition
    GoRoute(
      path: RoutePaths.nutrition,
      name: RoutePaths.nutrition,
      redirect: RouteGuards.authGuard,
      builder: (context, state) => const NutritionPage(),
    ),

    /// Profile
    GoRoute(
      path: RoutePaths.profile,
      name: RoutePaths.profile,
      redirect: RouteGuards.authGuard,
      builder: (context, state) => const ProfilePage(),
    ),

    /// Community
    GoRoute(
      path: RoutePaths.community,
      name: RoutePaths.community,
      builder: (context, state) => const CommunityPage(),
    ),
  ],
);
