import '../../domain/repositories/membership_payment_payer_profile_repository.dart';
import '../datasources/membership_payment_payer_profile_local_datasource.dart';
import '../datasources/membership_payment_payer_profile_remote_datasource.dart';

class SqliteMembershipPaymentPayerProfileRepository
    implements MembershipPaymentPayerProfileRepository {
  final MembershipPaymentPayerProfileLocalDatasource datasource;
  final MembershipPaymentPayerProfileRemoteDatasource remoteDatasource;

  const SqliteMembershipPaymentPayerProfileRepository({
    required this.datasource,
    this.remoteDatasource =
        const SupabaseMembershipPaymentPayerProfileRemoteDatasource(),
  });

  @override
  Future<String?> readFullName(String userId) async {
    final localFullName = (await datasource.readFullName(userId))?.trim();
    if (localFullName != null && localFullName.isNotEmpty) {
      return localFullName;
    }

    return remoteDatasource.readFullName(userId);
  }
}
