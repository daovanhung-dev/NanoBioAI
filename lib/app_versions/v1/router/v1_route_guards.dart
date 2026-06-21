import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/core/constants/routes/auth_route_paths.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class V1RouteGuards {
  static String? authGuard(BuildContext context, GoRouterState state) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return AuthRoutePaths.login;
    }

    return null;
  }

  static String? guestGuard(BuildContext context, GoRouterState state) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      return AuthRoutePaths.authGate;
    }

    return null;
  }
}
