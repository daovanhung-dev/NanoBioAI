import '../../domain/repositories/membership_payment_payer_profile_repository.dart';
import '../datasources/membership_payment_payer_profile_local_datasource.dart';
import '../datasources/membership_payment_payer_profile_remote_datasource.dart';

class SqliteMembershipPaymentPayerProfileRepository
    implements MembershipPaymentPayerProfileRepository {
  static const fallbackDisplayName = 'Khách hàng NanoBio';

  final MembershipPaymentPayerProfileLocalDatasource datasource;
  final MembershipPaymentPayerProfileRemoteDatasource remoteDatasource;

  const SqliteMembershipPaymentPayerProfileRepository({
    required this.datasource,
    this.remoteDatasource =
        const SupabaseMembershipPaymentPayerProfileRemoteDatasource(),
  });

  @override
  Future<String?> readFullName(String userId) async {
    // Payment checkout is authenticated and server-owned. Prefer the Supabase
    // profile so an empty/stale SQLite cache can never disable QR creation.
    try {
      final remoteFullName = (await remoteDatasource.readFullName(userId))
          ?.trim();
      if (remoteFullName != null && remoteFullName.isNotEmpty) {
        return remoteFullName;
      }
    } catch (_) {
      // Best-effort display metadata only; continue to the local projection.
    }

    try {
      final localFullName = (await datasource.readFullName(userId))?.trim();
      if (localFullName != null && localFullName.isNotEmpty) {
        return localFullName;
      }
    } catch (_) {
      // A local cache failure must not block the trusted payment RPC.
    }

    // The legacy RPC still accepts payer_full_name as review metadata. This
    // value is never encoded into VietQR; transfer content is the server-issued
    // NB reference only. Keeping a non-empty fallback preserves compatibility
    // while allowing checkout to proceed even when profile projections lag.
    return fallbackDisplayName;
  }
}
