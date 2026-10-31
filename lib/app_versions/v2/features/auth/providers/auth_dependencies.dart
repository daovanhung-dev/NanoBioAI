import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v2/features/auth/data/datasources/backend_auth_remote_datasource.dart';
import 'package:nano_app/app_versions/v2/features/auth/data/repositories/backend_auth_repository.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_failure.dart';
import 'package:nano_app/core/network/backend_api_client.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/repositories/auth_repository.dart';
import 'package:nano_app/core/config/auth_backend_availability.dart';

final authBackendAvailabilityProvider = Provider<AuthBackendAvailability>((
  ref,
) {
  return AuthBackendAvailability.missingConfiguration;
});

final v2AuthRemoteDatasourceProvider = Provider<BackendAuthRemoteDatasource>((
  ref,
) {
  _requireAuthBackendReady(ref);
  return BackendAuthRemoteDatasource(client: BackendApiClient.shared);
});

final v2AuthRepositoryProvider = Provider<AuthRepository>((ref) {
  _requireAuthBackendReady(ref);
  return BackendAuthRepository(
    datasource: ref.watch(v2AuthRemoteDatasourceProvider),
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
