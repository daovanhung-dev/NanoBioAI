import 'package:nano_app/core/network/backend_api_client.dart';

import '../../domain/entities/admin_wellness_reward_models.dart';

class BackendAdminWellnessRewardsRemoteDatasource {
  final BackendApiClient? clientOverride;

  const BackendAdminWellnessRewardsRemoteDatasource({this.clientOverride});

  BackendApiClient get _client => clientOverride ?? BackendApiClient.shared;

  Future<Object?> list({String query = '', int limit = 100}) => _client.request(
    'GET',
    '/api/v1/admin/business/wellness-rewards',
    query: {'q': query.trim(), 'limit': limit},
  );

  Future<Object?> upsertOffer(AdminRewardOfferCommand command) => _mutate(
    action: 'upsert_offer',
    targetId: command.offerId ?? '',
    reason: command.reason,
    idempotencyKey: command.idempotencyKey,
    payload: {
      'title': command.title.trim(),
      'description': command.description.trim(),
      'provider_name': command.providerName.trim(),
      'cost_points': command.costPoints,
      'reward_type': command.rewardType,
      'stock_count': command.stockCount,
      'eligible_plan_codes': command.eligiblePlanCodes,
      'available_from': command.availableFrom?.toUtc().toIso8601String(),
      'available_until': command.availableUntil?.toUtc().toIso8601String(),
      'voucher_expires_at': command.voucherExpiresAt?.toUtc().toIso8601String(),
      'is_active': command.isActive,
    },
  );

  Future<Object?> importCodes(AdminRewardCodeImportCommand command) => _mutate(
    action: 'import_codes',
    targetId: command.offerId,
    reason: command.reason,
    idempotencyKey: command.idempotencyKey,
    payload: {
      'codes': command.codes,
      'voucher_expires_at': command.voucherExpiresAt?.toUtc().toIso8601String(),
    },
  );

  Future<Object?> cancelRedemption({
    required String redemptionId,
    required String reason,
    required String idempotencyKey,
  }) => _mutate(
    action: 'cancel',
    targetId: redemptionId,
    reason: reason,
    idempotencyKey: idempotencyKey,
    payload: const {'external_revocation_confirmed': true},
  );

  Future<Object?> markRedemptionReceived({
    required String redemptionId,
    required String reason,
    required String idempotencyKey,
  }) => _mutate(
    action: 'mark_received',
    targetId: redemptionId,
    reason: reason,
    idempotencyKey: idempotencyKey,
    payload: const {},
  );

  Future<Object?> _mutate({
    required String action,
    required String targetId,
    required String reason,
    required String idempotencyKey,
    required Map<String, Object?> payload,
  }) => _client.request(
    'POST',
    '/api/v1/admin/business/wellness-rewards',
    body: {
      'action': action,
      'target_id': targetId,
      'reason': reason.trim(),
      'idempotency_key': idempotencyKey,
      'payload': payload,
    },
  );
}
