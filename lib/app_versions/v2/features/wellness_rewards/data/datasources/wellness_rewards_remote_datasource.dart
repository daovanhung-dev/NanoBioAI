import 'package:nano_app/core/network/backend_api_client.dart';

abstract class WellnessRewardsRemoteDatasource {
  Future<Map<String, Object?>> getSummary();

  Future<List<Map<String, Object?>>> listPointHistory({int limit = 100});

  Future<List<Map<String, Object?>>> listOffers({int limit = 100});

  Future<List<Map<String, Object?>>> listRedemptions({int limit = 100});

  Future<Map<String, Object?>> redeemOffer({
    required String offerId,
    required String idempotencyKey,
  });

  Future<String?> getVoucherCode(String redemptionId);
}

class BackendWellnessRewardsRemoteDatasource
    implements WellnessRewardsRemoteDatasource {
  final BackendApiClient? clientOverride;

  const BackendWellnessRewardsRemoteDatasource({this.clientOverride});

  BackendApiClient get _client => clientOverride ?? BackendApiClient.shared;

  @override
  Future<Map<String, Object?>> getSummary() =>
      _client.requestMap('GET', '/api/v1/wellness/rewards/summary');

  @override
  Future<List<Map<String, Object?>>> listPointHistory({
    int limit = 100,
  }) async => _mapList(
    await _client.request(
      'GET',
      '/api/v1/wellness/rewards/history',
      query: {'limit': limit},
    ),
  );

  @override
  Future<List<Map<String, Object?>>> listOffers({int limit = 100}) async =>
      _mapList(
        await _client.request(
          'GET',
          '/api/v1/wellness/rewards/offers',
          query: {'limit': limit},
        ),
      );

  @override
  Future<List<Map<String, Object?>>> listRedemptions({int limit = 100}) async =>
      _mapList(
        await _client.request(
          'GET',
          '/api/v1/wellness/rewards/redemptions',
          query: {'limit': limit},
        ),
      );

  @override
  Future<Map<String, Object?>> redeemOffer({
    required String offerId,
    required String idempotencyKey,
  }) => _client.requestMap(
    'POST',
    '/api/v1/wellness/rewards/redemptions',
    body: {'offer_id': offerId, 'idempotency_key': idempotencyKey},
  );

  @override
  Future<String?> getVoucherCode(String redemptionId) async {
    final response = await _client.requestMap(
      'GET',
      '/api/v1/wellness/rewards/redemptions/${Uri.encodeComponent(redemptionId)}/code',
    );
    final value = response['voucher_code'] ?? response['code'];
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

List<Map<String, Object?>> _mapList(Object? response) {
  if (response is! List) return const [];
  return response
      .whereType<Map>()
      .map((row) {
        return row.map((key, value) => MapEntry(key.toString(), value));
      })
      .toList(growable: false);
}
