import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/admin_wellness_reward_models.dart';

class AdminWellnessRewardsRemoteDatasource {
  final SupabaseClient? clientOverride;

  const AdminWellnessRewardsRemoteDatasource({this.clientOverride});

  Future<Object?> list({String query = '', int limit = 100}) {
    return _client().rpc(
      'admin_list_wellness_rewards',
      params: {'p_query': query.trim(), 'p_limit': limit},
    );
  }

  Future<Object?> upsertOffer(AdminRewardOfferCommand command) {
    return _client().rpc(
      'admin_upsert_reward_offer',
      params: {
        'p_offer_id': command.offerId,
        'p_title': command.title.trim(),
        'p_description': command.description.trim(),
        'p_provider_name': command.providerName.trim(),
        'p_cost_points': command.costPoints,
        'p_eligible_plan_codes': command.eligiblePlanCodes,
        'p_available_from': command.availableFrom?.toUtc().toIso8601String(),
        'p_available_until': command.availableUntil?.toUtc().toIso8601String(),
        'p_voucher_expires_at': command.voucherExpiresAt
            ?.toUtc()
            .toIso8601String(),
        'p_is_active': command.isActive,
        'p_reason': command.reason.trim(),
        'p_idempotency_key': command.idempotencyKey,
      },
    );
  }

  Future<Object?> importCodes(AdminRewardCodeImportCommand command) {
    return _client().rpc(
      'admin_import_reward_codes',
      params: {
        'p_offer_id': command.offerId,
        'p_codes': command.codes,
        'p_voucher_expires_at': command.voucherExpiresAt
            ?.toUtc()
            .toIso8601String(),
        'p_reason': command.reason.trim(),
        'p_idempotency_key': command.idempotencyKey,
      },
    );
  }

  Future<Object?> cancelRedemption({
    required String redemptionId,
    required String reason,
    required String idempotencyKey,
  }) {
    return _client().rpc(
      'admin_cancel_reward_redemption',
      params: {
        'p_redemption_id': redemptionId,
        'p_reason': reason.trim(),
        'p_external_revocation_confirmed': true,
        'p_idempotency_key': idempotencyKey,
      },
    );
  }

  SupabaseClient _client() {
    final client = clientOverride ?? Supabase.instance.client;
    if (client.auth.currentUser == null) {
      throw const AuthException('auth_required');
    }
    return client;
  }
}
