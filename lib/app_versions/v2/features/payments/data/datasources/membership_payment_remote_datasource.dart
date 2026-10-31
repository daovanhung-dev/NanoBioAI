import 'package:nano_app/core/network/backend_api_client.dart';

abstract interface class MembershipPaymentRemoteDatasource {
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

class BackendMembershipPaymentRemoteDatasource
    implements MembershipPaymentRemoteDatasource {
  final BackendApiClient? clientOverride;

  const BackendMembershipPaymentRemoteDatasource({this.clientOverride});

  BackendApiClient get _client => clientOverride ?? BackendApiClient.shared;

  @override
  Future<Object?> createMembershipPaymentRequest({
    required String planCode,
    required String billingCycle,
    required String idempotencyKey,
    required String payerFullName,
  }) => _client.requestMap(
    'POST',
    '/api/v1/payments/membership-requests',
    body: {
      'plan_code': planCode,
      'billing_cycle': billingCycle,
      'idempotency_key': idempotencyKey,
      'payer_full_name': payerFullName,
    },
  );

  @override
  Future<Object?> getMyMembershipPaymentRequest() =>
      _client.requestMap('GET', '/api/v1/payments/membership-requests/me');

  @override
  Future<Object?> confirmMyMembershipPaymentTransfer({
    required String paymentEventId,
  }) => _client.requestMap(
    'POST',
    '/api/v1/payments/membership-requests/$paymentEventId/confirm',
  );

  @override
  Future<Object?> cancelMyMembershipPaymentRequest({
    required String paymentEventId,
  }) => _client.requestMap(
    'POST',
    '/api/v1/payments/membership-requests/$paymentEventId/cancel',
  );
}
