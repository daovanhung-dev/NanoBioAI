import '../domain/repositories/membership_payment_payer_profile_repository.dart';

class ReadMembershipPaymentPayerName {
  final MembershipPaymentPayerProfileRepository repository;

  const ReadMembershipPaymentPayerName({required this.repository});

  Future<String?> execute(String? userId) {
    final normalizedUserId = userId?.trim();
    if (normalizedUserId == null || normalizedUserId.isEmpty) {
      return Future<String?>.value(null);
    }
    return repository.readFullName(normalizedUserId);
  }
}
