abstract class MembershipPaymentPayerProfileRepository {
  /// Reads the payer name stored locally for the authenticated user ID.
  Future<String?> readFullName(String userId);
}
