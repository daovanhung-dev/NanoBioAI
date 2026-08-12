import '../entities/membership_payment_models.dart';

abstract class MembershipPaymentRepository {
  Future<MembershipPaymentRequest> createRequest(
    CreateMembershipPaymentRequestCommand command,
  );

  Future<MembershipPaymentRequest?> fetchCurrentRequest();

  Future<MembershipPaymentRequest> confirmTransfer(String paymentEventId);

  Future<MembershipPaymentRequest> cancelRequest(String paymentEventId);
}
