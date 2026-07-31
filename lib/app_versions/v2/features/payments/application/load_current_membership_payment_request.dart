import '../domain/entities/membership_payment_models.dart';
import '../domain/repositories/membership_payment_repository.dart';

class LoadCurrentMembershipPaymentRequest {
  final MembershipPaymentRepository repository;

  const LoadCurrentMembershipPaymentRequest({required this.repository});

  Future<MembershipPaymentRequest?> execute() {
    return repository.fetchCurrentRequest();
  }
}
