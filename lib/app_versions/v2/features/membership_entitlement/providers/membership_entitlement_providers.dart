import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/data/datasources/effective_access_remote_datasource.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/data/repositories/supabase_effective_access_repository.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/entities/effective_access.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/repositories/effective_access_repository.dart';

final effectiveAccessRemoteDatasourceProvider =
    Provider<EffectiveAccessRemoteDatasource>((ref) {
      return const SupabaseEffectiveAccessRemoteDatasource();
    });

final effectiveAccessRepositoryProvider = Provider<EffectiveAccessRepository>((
  ref,
) {
  return SupabaseEffectiveAccessRepository(
    datasource: ref.watch(effectiveAccessRemoteDatasourceProvider),
  );
});

final effectiveAccessProvider = FutureProvider<EffectiveAccess?>((ref) {
  return ref.watch(effectiveAccessRepositoryProvider).fetchCurrentAccess();
});
