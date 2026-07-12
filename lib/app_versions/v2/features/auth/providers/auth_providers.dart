import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_route_state.dart';
import 'package:nano_app/app_versions/v2/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

import 'auth_dependencies.dart';

export 'auth_dependencies.dart';

final v2AuthControllerProvider =
    AsyncNotifierProvider<AuthController, AuthRouteState>(AuthController.new);

final v2AuthRouteStateProvider = v2AuthControllerProvider;

final currentAuthUserIdProvider = Provider<String?>((ref) {
  ref.watch(v2AuthChangesProvider);
  return currentSupabaseUserIdOrNull();
});
