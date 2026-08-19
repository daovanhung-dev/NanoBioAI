import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AdminPayoutProofRemoteDatasource {
  Future<String> uploadSalePayoutProof({
    required String conversionId,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
  });
}

class SupabaseAdminPayoutProofRemoteDatasource
    implements AdminPayoutProofRemoteDatasource {
  const SupabaseAdminPayoutProofRemoteDatasource();

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
        'sale-point-conversions/$safeConversion/${DateTime.now().millisecondsSinceEpoch}-$safeName';
    await Supabase.instance.client.storage
        .from('sale-payout-proofs')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );
    return path;
  }
}
