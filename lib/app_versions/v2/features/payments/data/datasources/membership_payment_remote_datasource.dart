import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MembershipPaymentRemoteDatasource {
  Future<Object?> createMembershipPaymentRequest({
    required String planCode,
    required String billingCycle,
    required String idempotencyKey,
    required String payerFullName,
  });

  Future<Object?> getMyMembershipPaymentRequest();

  Future<Object?> confirmMyMembershipPaymentTransfer({
    required String paymentEventId,
  });

  Future<Object?> cancelMyMembershipPaymentRequest({
    required String paymentEventId,
  });
}

class SupabaseMembershipPaymentRemoteDatasource
    implements MembershipPaymentRemoteDatasource {
  final SupabaseClient? clientOverride;

  const SupabaseMembershipPaymentRemoteDatasource({this.clientOverride});

  @override
  Future<Object?> createMembershipPaymentRequest({
    required String planCode,
    required String billingCycle,
    required String idempotencyKey,
    required String payerFullName,
  }) async {
    final client = _client();

    // The current rebuild contract in docs/supabase/setup.sql exposes the
    // four-argument RPC. Calling it first avoids a guaranteed PGRST202 round
    // trip on every QR request. Keep the three-argument call as rollout
    // compatibility for environments that already moved payer lookup fully
    // server-side.
    try {
      return await client.rpc(
        'create_membership_payment_request',
        params: {
          'p_plan_code': planCode,
          'p_billing_cycle': billingCycle,
          'p_idempotency_key': idempotencyKey,
          'p_payer_full_name': payerFullName,
        },
      );
    } on PostgrestException catch (error) {
      if (!_isCreateRpcSignatureUnavailable(error)) rethrow;

      return client.rpc(
        'create_membership_payment_request',
        params: {
          'p_plan_code': planCode,
          'p_billing_cycle': billingCycle,
          'p_idempotency_key': idempotencyKey,
        },
      );
    }
  }

  @override
  Future<Object?> getMyMembershipPaymentRequest() {
    return _client().rpc('get_my_membership_payment_request');
  }

  @override
  Future<Object?> confirmMyMembershipPaymentTransfer({
    required String paymentEventId,
  }) {
    return _client().rpc(
      'confirm_my_membership_payment_transfer',
      params: {'p_payment_event_id': paymentEventId},
    );
  }

  @override
  Future<Object?> cancelMyMembershipPaymentRequest({
    required String paymentEventId,
  }) {
    return _client().rpc(
      'cancel_my_membership_payment_request',
      params: {'p_payment_event_id': paymentEventId},
    );
  }

  SupabaseClient _client() {
    final client = clientOverride ?? Supabase.instance.client;
    if (client.auth.currentUser == null) {
      throw const AuthException('Missing authenticated session.');
    }
    return client;
  }
}

bool _isCreateRpcSignatureUnavailable(PostgrestException error) {
  if (error.code == 'PGRST202') return true;
  final text = '${error.message} ${error.details ?? ''} ${error.hint ?? ''}'
      .toLowerCase();
  return text.contains('create_membership_payment_request') &&
      (text.contains('could not find the function') ||
          text.contains('schema cache') ||
          text.contains('function') && text.contains('does not exist'));
}
