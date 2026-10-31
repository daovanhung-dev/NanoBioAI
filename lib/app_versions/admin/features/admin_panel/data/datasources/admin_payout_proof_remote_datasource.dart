import 'dart:typed_data';

import 'package:nano_app/core/network/backend_api_client.dart';

abstract interface class AdminPayoutProofRemoteDatasource {
  Future<String> uploadSalePayoutProof({
    required String conversionId,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
  });
}

class BackendAdminPayoutProofRemoteDatasource
    implements AdminPayoutProofRemoteDatasource {
  final BackendApiClient? clientOverride;

  const BackendAdminPayoutProofRemoteDatasource({this.clientOverride});

  @override
  Future<String> uploadSalePayoutProof({
    required String conversionId,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final safeConversion = conversionId.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final path =
        '/api/v1/files/sale-payout-proofs?conversion_id=${Uri.encodeQueryComponent(safeConversion)}';
    final result = await (clientOverride ?? BackendApiClient.shared)
        .uploadBytes(
          path,
          bytes: bytes,
          fileName: safeName,
          contentType: contentType,
        );
    final id = result['id']?.toString().trim();
    if (id == null || id.isEmpty) {
      throw const FormatException('File upload response has no identifier.');
    }
    return id;
  }
}
