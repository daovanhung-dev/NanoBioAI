import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_route_state.dart';
import 'package:nano_app/app_versions/v2/features/auth/presentation/controllers/auth_controller.dart';

export 'auth_dependencies.dart';

final v2AuthControllerProvider =
    AsyncNotifierProvider<AuthController, AuthRouteState>(AuthController.new);

final v2AuthRouteStateProvider = v2AuthControllerProvider;

/// Canonical authenticated identity for app-surface and feature routing.
///
/// The raw Supabase auth stream remains an invalidation trigger inside
/// [AuthController], but root identity must follow the controller's resolved
/// route state. This prevents a transient/delayed auth-stream value from
/// remounting the app as signed out after a successful first login.
final currentAuthUserIdProvider = Provider<String?>((ref) {
  final routeState = ref.watch(v2AuthControllerProvider).value;
  final userId = routeState?.userId?.trim();
  return userId == null || userId.isEmpty ? null : userId;
});
