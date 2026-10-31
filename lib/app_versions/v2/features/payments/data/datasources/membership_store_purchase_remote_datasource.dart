import 'package:nano_app/core/network/backend_api_client.dart';

import '../../domain/entities/store_membership_purchase.dart';

abstract interface class MembershipStorePurchaseRemoteDatasource {
  Future<StorePurchaseVerificationResult> verifyPurchase(
    StoreMembershipPurchase purchase,
  );
}

class BackendMembershipStorePurchaseRemoteDatasource
    implements MembershipStorePurchaseRemoteDatasource {
  final BackendApiClient? clientOverride;

  const BackendMembershipStorePurchaseRemoteDatasource({this.clientOverride});

  @override
  Future<StorePurchaseVerificationResult> verifyPurchase(
    StoreMembershipPurchase purchase,
  ) async {
    final client = clientOverride ?? BackendApiClient.shared;
    if (client.session == null) {
      throw const MembershipStoreBillingException.authRequired();
    }

    try {
      final data = await client.requestMap(
        'POST',
        '/api/v1/payments/google-play/verify',
        body: {
          'package_name': StoreMembershipProduct.androidPackageName,
          'product_id': purchase.productId,
          'purchase_token': purchase.serverVerificationData,
        },
      );
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
    } on BackendApiException catch (error) {
      if (error.statusCode == 401) {
        throw const MembershipStoreBillingException.authRequired();
      }
      throw MembershipStoreBillingException(
        error.businessCode,
        error.message,
        retryable: error.statusCode >= 500 || error.statusCode == 0,
      );
    }
  }
}

String? _readString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _readDate(Object? value) {
  final text = _readString(value);
  return text == null ? null : DateTime.tryParse(text);
}
