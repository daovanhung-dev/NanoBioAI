import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/constant.dart';

class AppNavigator {

  static void goDashboard(BuildContext context) {
    context.go(RoutePaths.dashboard);
  }

  static void goLogin(BuildContext context) {
    context.go(RoutePaths.login);
  }

  static void goProfile(BuildContext context) {
    context.go(RoutePaths.profile);
  }

  static void goAIChat(BuildContext context) {
    context.go(RoutePaths.aiChat);
  }

  static void back(BuildContext context) {
    context.pop();
  }

  static void goOnboarding(BuildContext context) {
    context.go(RoutePaths.onboarding);
  }
}
