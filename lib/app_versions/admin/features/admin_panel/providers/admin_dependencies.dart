import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/data/datasources/admin_supabase_datasource.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/data/repositories/admin_repository_impl.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/repositories/admin_repository.dart';
import 'package:nano_app/core/config/auth_backend_availability.dart';

final adminBackendAvailabilityProvider = Provider<AuthBackendAvailability>((ref) {
  return AuthBackendAvailability.missingConfiguration;
});

final adminSupabaseDatasourceProvider = Provider<AdminSupabaseDatasource>((ref) {
  return const AdminSupabaseDatasource();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(
    datasource: ref.watch(adminSupabaseDatasourceProvider),
  );
});

final adminAuthChangesProvider = StreamProvider<void>((ref) {
  if (!ref.watch(adminBackendAvailabilityProvider).isReady) {
    return const Stream<void>.empty();
  }
  return ref.watch(adminRepositoryProvider).watchAuthChanges();
});
