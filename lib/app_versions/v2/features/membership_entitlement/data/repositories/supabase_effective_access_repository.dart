import 'package:nano_app/app_versions/v2/features/membership_entitlement/data/datasources/effective_access_remote_datasource.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/entities/effective_access.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/repositories/effective_access_repository.dart';

class SupabaseEffectiveAccessRepository implements EffectiveAccessRepository {
  final EffectiveAccessRemoteDatasource datasource;

  const SupabaseEffectiveAccessRepository({required this.datasource});

  @override
  Future<EffectiveAccess?> fetchCurrentAccess() {
    return datasource.fetchCurrentAccess();
  }
}
