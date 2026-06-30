import '../entities/membership_payment_models.dart';

abstract class MembershipPaymentRepository {
  Future<MembershipPaymentRequest> createRequest(
    CreateMembershipPaymentRequestCommand command,
  );
}
