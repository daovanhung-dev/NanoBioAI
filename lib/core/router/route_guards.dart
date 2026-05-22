import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/constant.dart';


class RouteGuards {
  static String? authGuard(BuildContext context, GoRouterState state) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return RoutePaths.login;
    }

    return null;
  }

  static String? guestGuard(BuildContext context, GoRouterState state) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      return RoutePaths.dashboard;
    }

    return null;
  }
}
