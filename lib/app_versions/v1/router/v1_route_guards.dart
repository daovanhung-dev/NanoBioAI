import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/constants/routes/auth_route_paths.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

class V1RouteGuards {
  static const Set<String> registeredV1Paths = {
    V1RoutePaths.splash,
    V1RoutePaths.login,
    V1RoutePaths.register,
    V1RoutePaths.onboardingEntry,
    V1RoutePaths.onboarding,
    V1RoutePaths.dashboard,
    V1RoutePaths.menu,
    V1RoutePaths.mealPlan,
    V1RoutePaths.healthTracking,
    V1RoutePaths.todayTasks,
    V1RoutePaths.waterTracking,
    V1RoutePaths.weeklySummary,
    V1RoutePaths.personalGoals,
    V1RoutePaths.quickCare,
    V1RoutePaths.gentleCare,
    V1RoutePaths.namiCare,
    V1RoutePaths.bodyMetrics,
    V1RoutePaths.lifestyleSchedule,
    V1RoutePaths.dailyRoutinePreferences,
    V1RoutePaths.sleepTracking,
    V1RoutePaths.stressTracking,
    V1RoutePaths.aiChat,
    V1RoutePaths.aiVoice,
    V1RoutePaths.nutrition,
    V1RoutePaths.nutritionProfile,
    V1RoutePaths.profile,
    V1RoutePaths.community,
  };

  static const Set<String> guestAllowedPaths = {
    V1RoutePaths.splash,
    V1RoutePaths.login,
    V1RoutePaths.register,
    V1RoutePaths.onboardingEntry,
    V1RoutePaths.onboarding,
    V1RoutePaths.dashboard,
    V1RoutePaths.menu,
    V1RoutePaths.mealPlan,
    V1RoutePaths.healthTracking,
    V1RoutePaths.todayTasks,
    V1RoutePaths.waterTracking,
    V1RoutePaths.weeklySummary,
    V1RoutePaths.personalGoals,
    V1RoutePaths.quickCare,
    V1RoutePaths.gentleCare,
    V1RoutePaths.namiCare,
    V1RoutePaths.bodyMetrics,
    V1RoutePaths.lifestyleSchedule,
    V1RoutePaths.dailyRoutinePreferences,
    V1RoutePaths.sleepTracking,
    V1RoutePaths.stressTracking,
    AuthRoutePaths.authGate,
    AuthRoutePaths.login,
    AuthRoutePaths.register,
    AuthRoutePaths.verifyEmail,
    AuthRoutePaths.forgotPassword,
    AuthRoutePaths.resetPassword,
    AuthRoutePaths.authCallback,
  };

  static String? authGuard(BuildContext context, GoRouterState state) {
    final user = currentSupabaseUserIdOrNull();

    if (user == null) {
      return AuthRoutePaths.login;
    }

    return null;
  }

  static String? guestGuard(BuildContext context, GoRouterState state) {
    final user = currentSupabaseUserIdOrNull();

    if (user != null) {
      return AuthRoutePaths.authGate;
    }

    return null;
  }

  static String? guestAllowlistGuard(
    BuildContext context,
    GoRouterState state,
  ) {
    final user = currentSupabaseUserIdOrNull();
    if (user != null) return null;

    return guestRedirectForPath(state.uri.path);
  }

  static String? guestRedirectForPath(String path) {
    return isGuestAllowedPath(path) ? null : AuthRoutePaths.login;
  }

  static bool isRegisteredV1Path(String path) {
    final normalized = path.trim().isEmpty ? V1RoutePaths.splash : path.trim();
    return registeredV1Paths.contains(normalized);
  }

  static bool isGuestAllowedPath(String path) {
    final normalized = path.trim().isEmpty ? V1RoutePaths.splash : path.trim();
    return guestAllowedPaths.contains(normalized);
  }
}
