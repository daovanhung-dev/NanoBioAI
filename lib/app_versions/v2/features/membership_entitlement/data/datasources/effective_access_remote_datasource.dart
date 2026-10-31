import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/entities/effective_access.dart';
import 'package:nano_app/core/network/backend_api_client.dart';

abstract class EffectiveAccessRemoteDatasource {
  Future<EffectiveAccess?> fetchCurrentAccess();
}

class BackendEffectiveAccessRemoteDatasource
    implements EffectiveAccessRemoteDatasource {
  final BackendApiClient? clientOverride;

  const BackendEffectiveAccessRemoteDatasource({this.clientOverride});

  BackendApiClient? get _client => clientOverride ?? BackendApiClient.shared;

  @override
  Future<EffectiveAccess?> fetchCurrentAccess() async {
    final client = _client;
    final userId = client?.currentUserId;
    if (client == null || userId == null) return null;
    final row = await client.requestMap('GET', '/api/v1/membership/me');
    return EffectiveAccess.fromMap(row);
  }
}
