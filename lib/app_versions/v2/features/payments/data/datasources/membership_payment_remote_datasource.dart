import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MembershipPaymentRemoteDatasource {
  Future<Object?> createMembershipPaymentRequest({
    required String planCode,
    required String billingCycle,
    required String idempotencyKey,
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
  }) {
    final client = _client();
    return client.rpc(
      'create_membership_payment_request',
      params: {
        'p_plan_code': planCode,
        'p_billing_cycle': billingCycle,
        'p_idempotency_key': idempotencyKey,
      },
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
