import 'package:nano_app/core/network/backend_api_client.dart';

abstract interface class WellnessRankRemoteDatasource {
  Future<Map<String, Object?>> loadSummary();
}

class BackendWellnessRankRemoteDatasource
    implements WellnessRankRemoteDatasource {
  final BackendApiClient? clientOverride;

  const BackendWellnessRankRemoteDatasource({this.clientOverride});

  @override
  Future<Map<String, Object?>> loadSummary() =>
      (clientOverride ?? BackendApiClient.shared).requestMap(
        'GET',
        '/api/v1/wellness/rank/summary',
      );
}
