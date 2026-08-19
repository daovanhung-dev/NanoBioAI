import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/admin_payout_proof_remote_datasource.dart';
import '../data/repositories/supabase_admin_payout_proof_repository.dart';
import '../domain/repositories/admin_payout_proof_repository.dart';

final adminPayoutProofRemoteDatasourceProvider =
    Provider<AdminPayoutProofRemoteDatasource>((ref) {
      return const SupabaseAdminPayoutProofRemoteDatasource();
    });

final adminPayoutProofRepositoryProvider = Provider<AdminPayoutProofRepository>(
  (ref) {
    return SupabaseAdminPayoutProofRepository(
      datasource: ref.watch(adminPayoutProofRemoteDatasourceProvider),
    );
  },
);
