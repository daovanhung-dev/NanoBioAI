import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v2/features/auth/data/datasources/supabase_auth_remote_datasource.dart';
import 'package:nano_app/app_versions/v2/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_failure.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/repositories/auth_repository.dart';
import 'package:nano_app/core/config/app_env.dart';
import 'package:nano_app/core/config/auth_backend_availability.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authBackendAvailabilityProvider = Provider<AuthBackendAvailability>((
  ref,
) {
  return AuthBackendAvailability.missingConfiguration;
});

final authEmailConfirmationRequiredProvider = Provider<bool>((ref) {
  return AppEnv.boolValue('AUTH_CONFIRM_EMAIL_REQUIRED', defaultValue: true);
});

final v2AuthRemoteDatasourceProvider = Provider<SupabaseAuthRemoteDatasource>((
  ref,
) {
  _requireAuthBackendReady(ref);
  return SupabaseAuthRemoteDatasource(client: Supabase.instance.client);
});

final v2AuthRepositoryProvider = Provider<AuthRepository>((ref) {
  _requireAuthBackendReady(ref);
  return SupabaseAuthRepository(
    datasource: ref.watch(v2AuthRemoteDatasourceProvider),
    requiresEmailConfirmation: ref.watch(authEmailConfirmationRequiredProvider),
  );
});

final v2AuthChangesProvider = StreamProvider<String?>((ref) {
  if (!ref.watch(authBackendAvailabilityProvider).isReady) {
    return const Stream<String?>.empty();
  }
  return ref.watch(v2AuthRepositoryProvider).watchAuthChanges();
});

void _requireAuthBackendReady(Ref ref) {
  final availability = ref.watch(authBackendAvailabilityProvider);
  if (!availability.isReady) {
    throw authBackendUnavailableFailure(availability);
  }
}
