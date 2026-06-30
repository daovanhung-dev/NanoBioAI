import '../domain/entities/membership_payment_models.dart';
import '../domain/repositories/membership_payment_repository.dart';

class CreateMembershipPaymentRequest {
  final MembershipPaymentRepository repository;

  const CreateMembershipPaymentRequest({required this.repository});

  Future<MembershipPaymentRequest> execute(
    CreateMembershipPaymentRequestCommand command,
  ) {
    final planCode = command.planCode.trim();
    final billingCycle = command.billingCycle.trim();
    final idempotencyKey = command.idempotencyKey.trim();
    if (planCode.isEmpty ||
        billingCycle.isEmpty ||
        idempotencyKey.isEmpty ||
        !const {'plus', 'family_plus'}.contains(planCode) ||
        !const {'monthly', 'yearly'}.contains(billingCycle)) {
      throw const MembershipPaymentException.invalidCommand();
    }
    return repository.createRequest(
      CreateMembershipPaymentRequestCommand(
        planCode: planCode,
        billingCycle: billingCycle,
        idempotencyKey: idempotencyKey,
      ),
    );
  }
}
