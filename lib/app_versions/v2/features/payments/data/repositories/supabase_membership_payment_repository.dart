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
    return MembershipPaymentRequest.fromMap(_firstMap(response));
  }

  @override
  Future<MembershipPaymentRequest?> fetchCurrentRequest() async {
    final response = await datasource.getMyMembershipPaymentRequest();
    final map = _firstMapOrNull(response);
    return map == null ? null : MembershipPaymentRequest.fromMap(map);
  }

  @override
  Future<MembershipPaymentRequest> confirmTransfer(
    String paymentEventId,
  ) async {
    final response = await datasource.confirmMyMembershipPaymentTransfer(
      paymentEventId: paymentEventId,
    );
    return MembershipPaymentRequest.fromMap(_firstMap(response));
  }

  @override
  Future<MembershipPaymentRequest> cancelRequest(String paymentEventId) async {
    final response = await datasource.cancelMyMembershipPaymentRequest(
      paymentEventId: paymentEventId,
    );
    return MembershipPaymentRequest.fromMap(_firstMap(response));
  }
}

Map<String, Object?> _firstMap(Object? response) {
  return _firstMapOrNull(response) ?? const {};
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
