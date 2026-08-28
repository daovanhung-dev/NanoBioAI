import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/store_membership_purchase.dart';

abstract interface class MembershipStorePurchaseRemoteDatasource {
  Future<StorePurchaseVerificationResult> verifyPurchase(
    StoreMembershipPurchase purchase,
  );
}

class SupabaseMembershipStorePurchaseRemoteDatasource
    implements MembershipStorePurchaseRemoteDatasource {
  final SupabaseClient? clientOverride;

  const SupabaseMembershipStorePurchaseRemoteDatasource({this.clientOverride});

  @override
  Future<StorePurchaseVerificationResult> verifyPurchase(
    StoreMembershipPurchase purchase,
  ) async {
    final client = clientOverride ?? Supabase.instance.client;
    if (client.auth.currentUser == null) {
      throw const MembershipStoreBillingException.authRequired();
    }

    final response = await client.functions.invoke(
      'google-play-verify-purchase',
      body: {
        'package_name': StoreMembershipProduct.androidPackageName,
        'product_id': purchase.productId,
        'purchase_token': purchase.serverVerificationData,
      },
    );
    final data = _asMap(response.data);
    final status = switch (data['status']?.toString().trim().toLowerCase()) {
      'verified' => StoreVerificationStatus.verified,
      'pending' => StoreVerificationStatus.pending,
      _ => StoreVerificationStatus.rejected,
    };
    return StorePurchaseVerificationResult(
      status: status,
      planCode: _readString(data['plan_code']),
      expiresAt: _readDate(data['expires_at']),
      retryable: data['retryable'] == true,
      message: _readString(data['message']) ?? '',
    );
  }
}

Map<String, Object?> _asMap(Object? value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

String? _readString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _readDate(Object? value) {
  final text = _readString(value);
  return text == null ? null : DateTime.tryParse(text);
}
