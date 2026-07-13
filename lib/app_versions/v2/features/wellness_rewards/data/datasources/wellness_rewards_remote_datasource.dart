import 'package:supabase_flutter/supabase_flutter.dart';

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

class SupabaseWellnessRewardsRemoteDatasource
    implements WellnessRewardsRemoteDatasource {
  final SupabaseClient? clientOverride;

  const SupabaseWellnessRewardsRemoteDatasource({this.clientOverride});

  @override
  Future<Map<String, Object?>> getSummary() async {
    final response = await _client().rpc('get_my_wellness_reward_summary');
    return _firstMap(response);
  }

  @override
  Future<List<Map<String, Object?>>> listPointHistory({int limit = 100}) async {
    final response = await _client().rpc(
      'list_my_wellness_point_history',
      params: {'p_limit': limit},
    );
    return _mapList(response);
  }

  @override
  Future<List<Map<String, Object?>>> listOffers({int limit = 100}) async {
    final response = await _client().rpc(
      'list_my_reward_offers',
      params: {'p_limit': limit},
    );
    return _mapList(response);
  }

  @override
  Future<List<Map<String, Object?>>> listRedemptions({int limit = 100}) async {
    final response = await _client().rpc(
      'list_my_reward_redemptions',
      params: {'p_limit': limit},
    );
    return _mapList(response);
  }

  @override
  Future<Map<String, Object?>> redeemOffer({
    required String offerId,
    required String idempotencyKey,
  }) async {
    final response = await _client().rpc(
      'redeem_my_reward_offer',
      params: {'p_offer_id': offerId, 'p_idempotency_key': idempotencyKey},
    );
    return _firstMap(response);
  }

  @override
  Future<String?> getVoucherCode(String redemptionId) async {
    final response = await _client().rpc(
      'get_my_reward_code',
      params: {'p_redemption_id': redemptionId},
    );
    final map = _firstMap(response);
    final value = map['voucher_code'] ?? map['code'];
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  SupabaseClient _client() {
    final client = clientOverride ?? Supabase.instance.client;
    if (client.auth.currentUser == null) {
      throw const AuthException('auth_required');
    }
    return client;
  }
}

Map<String, Object?> _firstMap(Object? response) {
  if (response is Map) return _copyMap(response);
  if (response is List && response.isNotEmpty && response.first is Map) {
    return _copyMap(response.first as Map);
  }
  return const {};
}

List<Map<String, Object?>> _mapList(Object? response) {
  final normalized = response is Map && response['items'] is List
      ? response['items']
      : response;
  if (normalized is! List) return const [];
  return normalized.whereType<Map>().map(_copyMap).toList(growable: false);
}

Map<String, Object?> _copyMap(Map<dynamic, dynamic> source) {
  return source.map((key, value) => MapEntry(key.toString(), value));
}
