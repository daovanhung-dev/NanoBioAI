import '../../domain/entities/membership_payment_models.dart';
import '../../domain/repositories/membership_payment_repository.dart';
import '../datasources/membership_payment_remote_datasource.dart';

class SupabaseMembershipPaymentRepository
    implements MembershipPaymentRepository {
  final MembershipPaymentRemoteDatasource datasource;

  const SupabaseMembershipPaymentRepository({required this.datasource});

  @override
  Future<MembershipPaymentRequest> createRequest(
    CreateMembershipPaymentRequestCommand command,
  ) async {
    final response = await datasource.createMembershipPaymentRequest(
      planCode: command.planCode,
      billingCycle: command.billingCycle,
      idempotencyKey: command.idempotencyKey,
      payerFullName: command.payerFullName,
    );
    return _validateCreateResponse(_parseRequiredRequest(response));
  }

  @override
  Future<MembershipPaymentRequest?> fetchCurrentRequest() async {
    final response = await datasource.getMyMembershipPaymentRequest();
    final map = _firstMapOrNull(response);
    if (map == null) return null;
    return MembershipPaymentRequest.fromMap(map);
  }

  @override
  Future<MembershipPaymentRequest> confirmTransfer(
    String paymentEventId,
  ) async {
    final response = await datasource.confirmMyMembershipPaymentTransfer(
      paymentEventId: paymentEventId,
    );
    return _parseRequiredRequest(response);
  }

  @override
  Future<MembershipPaymentRequest> cancelRequest(String paymentEventId) async {
    final response = await datasource.cancelMyMembershipPaymentRequest(
      paymentEventId: paymentEventId,
    );
    return _parseRequiredRequest(response);
  }
}

MembershipPaymentRequest _validateCreateResponse(
  MembershipPaymentRequest request,
) {
  if (request.id.trim().isEmpty) {
    throw const MembershipPaymentException.invalidServerPaymentPayload();
  }

  // A newly created request should either be ready for transfer or be an
  // already-open request returned idempotently by Supabase. Only the transfer
  // state requires a complete QR payload.
  if (request.isAwaitingTransfer && !request.hasTransferDetails) {
    throw const MembershipPaymentException.invalidServerPaymentPayload();
  }

  return request;
}

MembershipPaymentRequest _parseRequiredRequest(Object? response) {
  final map = _firstMapOrNull(response);
  if (map == null || map.isEmpty) {
    throw const MembershipPaymentException.invalidServerPaymentPayload();
  }
  return MembershipPaymentRequest.fromMap(map);
}

Map<String, Object?>? _firstMapOrNull(Object? response) {
  if (response is Map) return _copyMap(response);
  if (response is List && response.isNotEmpty) {
    final first = response.first;
    if (first is Map) return _copyMap(first);
  }
  return null;
}

Map<String, Object?> _copyMap(Map<dynamic, dynamic> map) {
  return map.map((key, value) => MapEntry(key.toString(), value));
}
