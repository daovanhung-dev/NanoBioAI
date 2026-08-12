import '../domain/entities/membership_payment_models.dart';
import '../domain/repositories/membership_payment_repository.dart';

class CancelMembershipPaymentRequest {
  final MembershipPaymentRepository repository;

  const CancelMembershipPaymentRequest({required this.repository});

  Future<MembershipPaymentRequest> execute(String paymentEventId) {
    final normalizedPaymentEventId = paymentEventId.trim();
    if (normalizedPaymentEventId.isEmpty) {
      throw const MembershipPaymentException.invalidCancellation();
    }
    return repository.cancelRequest(normalizedPaymentEventId);
  }
}
