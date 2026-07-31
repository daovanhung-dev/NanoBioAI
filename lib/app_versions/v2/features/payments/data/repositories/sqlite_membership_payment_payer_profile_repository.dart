import '../../domain/repositories/membership_payment_payer_profile_repository.dart';
import '../datasources/membership_payment_payer_profile_local_datasource.dart';

class SqliteMembershipPaymentPayerProfileRepository
    implements MembershipPaymentPayerProfileRepository {
  final MembershipPaymentPayerProfileLocalDatasource datasource;

  const SqliteMembershipPaymentPayerProfileRepository({
    required this.datasource,
  });

  @override
  Future<String?> readFullName(String userId) {
    return datasource.readFullName(userId);
  }
}
