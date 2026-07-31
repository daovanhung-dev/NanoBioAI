import '../domain/entities/membership_payment_models.dart';
import '../domain/repositories/membership_payment_repository.dart';

class ConfirmMembershipPaymentTransfer {
  final MembershipPaymentRepository repository;

  const ConfirmMembershipPaymentTransfer({required this.repository});

  Future<MembershipPaymentRequest> execute(String paymentEventId) {
    final normalizedPaymentEventId = paymentEventId.trim();
    if (normalizedPaymentEventId.isEmpty) {
      throw const MembershipPaymentException.invalidTransferConfirmation();
    }
    return repository.confirmTransfer(normalizedPaymentEventId);
  }
}
