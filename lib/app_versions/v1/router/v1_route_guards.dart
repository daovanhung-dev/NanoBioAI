import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'v1_route_paths.dart';

class V1RouteGuards {
  static String? authGuard(BuildContext context, GoRouterState state) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return V1RoutePaths.login;
    }

    return null;
  }

  static String? guestGuard(BuildContext context, GoRouterState state) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      return V1RoutePaths.dashboard;
    }

    return null;
  }
}
