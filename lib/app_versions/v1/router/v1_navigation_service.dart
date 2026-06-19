import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'v1_route_paths.dart';

class V1AppNavigator {
  static void goDashboard(BuildContext context) {
    context.go(V1RoutePaths.dashboard);
  }

  static void goLogin(BuildContext context) {
    context.go(V1RoutePaths.login);
  }

  static void goProfile(BuildContext context) {
    context.go(V1RoutePaths.profile);
  }

  static void goMenu(BuildContext context) {
    context.go(V1RoutePaths.menu);
  }

  static void goMealPlan(BuildContext context) {
    context.go(V1RoutePaths.mealPlan);
  }

  static void goAIChat(BuildContext context) {
    context.go(V1RoutePaths.aiChat);
  }

  static void back(BuildContext context) {
    context.pop();
  }

  static void goOnboarding(BuildContext context) {
    context.go(V1RoutePaths.onboarding);
  }
}
