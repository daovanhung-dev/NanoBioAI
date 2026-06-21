import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/auth/presentation/pages/v1_auth_entry_page.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/dashboard.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/presentation/pages/daily_health_tracking_page.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/presentation/pages/nutrition_page.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/onboarding.dart';
import 'package:nano_app/app_versions/v1/features/profile/presentation/pages/profile_page.dart';
import 'package:nano_app/app_versions/v1/features/splash/splash.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart';
import 'package:nano_app/app_versions/v1/features/community/presentation/pages/community_page.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart';
import 'package:nano_app/app_versions/v1/features/stress_tracking/presentation/pages/stress_tracking_page.dart';

import 'v1_route_guards.dart';
import 'v1_route_paths.dart';

final v1Routes = <RouteBase>[
  /// Splash
  GoRoute(
    path: V1RoutePaths.splash,
    name: V1RoutePaths.splash,
    builder: (context, state) => SplashPage(),
  ),

  /// Login
  GoRoute(
    path: V1RoutePaths.login,
    name: V1RoutePaths.login,
    redirect: V1RouteGuards.guestGuard,
    builder: (context, state) =>
        const V1AuthEntryPage(intent: V1AuthEntryIntent.login),
  ),

  /// Register
  GoRoute(
    path: V1RoutePaths.register,
    name: V1RoutePaths.register,
    builder: (context, state) =>
        const V1AuthEntryPage(intent: V1AuthEntryIntent.register),
  ),

  /// Dashboard
  GoRoute(
    path: V1RoutePaths.dashboard,
    name: V1RoutePaths.dashboard,
    // redirect: V1RouteGuards.authGuard,
    builder: (context, state) => const DashboardPage(),
  ),

  /// Onboarding
  GoRoute(
    path: V1RoutePaths.onboardingEntry,
    name: V1RoutePaths.onboardingEntry,
    builder: (context, state) => const OnboardingEntryPage(),
  ),

  /// Onboarding
  GoRoute(
    path: V1RoutePaths.onboarding,
    name: V1RoutePaths.onboarding,
    builder: (context, state) => const OnboardingPage(),
  ),

  /// Menu
  GoRoute(
    path: V1RoutePaths.menu,
    name: V1RoutePaths.menu,
    builder: (context, state) => const MainNavigationPage(),
  ),

  /// Meal Plan
  GoRoute(
    path: V1RoutePaths.mealPlan,
    name: V1RoutePaths.mealPlan,
    builder: (context, state) => const MealPlanPage(),
  ),

  /// Daily Health Tracking
  GoRoute(
    path: V1RoutePaths.healthTracking,
    name: V1RoutePaths.healthTracking,
    builder: (context, state) => const DailyHealthTrackingPage(),
  ),

  /// Lifestyle Schedule
  GoRoute(
    path: V1RoutePaths.lifestyleSchedule,
    name: V1RoutePaths.lifestyleSchedule,
    builder: (context, state) => const LifestyleSchedulePage(),
  ),

  /// Sleep Tracking
  GoRoute(
    path: V1RoutePaths.sleepTracking,
    name: V1RoutePaths.sleepTracking,
    builder: (context, state) => const SleepTrackingPage(),
  ),

  /// Stress Tracking
  GoRoute(
    path: V1RoutePaths.stressTracking,
    name: V1RoutePaths.stressTracking,
    builder: (context, state) => const StressTrackingPage(),
  ),

  /// AI Chat
  GoRoute(
    path: V1RoutePaths.aiChat,
    name: V1RoutePaths.aiChat,
    redirect: V1RouteGuards.authGuard,
    builder: (context, state) => const AIChatScreen(),
  ),

  /// Nutrition
  GoRoute(
    path: V1RoutePaths.nutrition,
    name: V1RoutePaths.nutrition,
    redirect: V1RouteGuards.authGuard,
    builder: (context, state) => const NutritionPage(),
  ),

  /// Profile
  GoRoute(
    path: V1RoutePaths.profile,
    name: V1RoutePaths.profile,
    redirect: V1RouteGuards.authGuard,
    builder: (context, state) => const ProfilePage(),
  ),

  /// Community
  GoRoute(
    path: V1RoutePaths.community,
    name: V1RoutePaths.community,
    builder: (context, state) => const CommunityPage(),
  ),
];

final v1Router = GoRouter(
  initialLocation: V1RoutePaths.splash,
  routes: v1Routes,
);
