import 'dart:typed_data';

abstract interface class AdminPayoutProofRepository {
  Future<String> uploadSalePayoutProof({
    required String conversionId,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
  });
}
