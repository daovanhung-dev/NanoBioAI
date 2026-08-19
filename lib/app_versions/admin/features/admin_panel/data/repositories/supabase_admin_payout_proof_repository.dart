import 'dart:typed_data';

import '../../domain/repositories/admin_payout_proof_repository.dart';
import '../datasources/admin_payout_proof_remote_datasource.dart';

class SupabaseAdminPayoutProofRepository implements AdminPayoutProofRepository {
  const SupabaseAdminPayoutProofRepository({required this.datasource});

  final AdminPayoutProofRemoteDatasource datasource;

  @override
  Future<String> uploadSalePayoutProof({
    required String conversionId,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
  }) {
    return datasource.uploadSalePayoutProof(
      conversionId: conversionId,
      fileName: fileName,
      contentType: contentType,
      bytes: bytes,
    );
  }
}
