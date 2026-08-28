import 'package:in_app_purchase/in_app_purchase.dart';

import '../../domain/entities/store_membership_purchase.dart';

class GooglePlayProductDetailsDto {
  final ProductDetails platformDetails;
  final StoreMembershipProduct product;

  const GooglePlayProductDetailsDto({
    required this.platformDetails,
    required this.product,
  });

  StoreProductDetails toEntity() {
    return StoreProductDetails(
      product: product,
      title: platformDetails.title,
      description: platformDetails.description,
      displayPrice: platformDetails.price,
      rawPrice: platformDetails.rawPrice,
      currencyCode: platformDetails.currencyCode,
    );
  }
}

class GooglePlayPurchaseDto {
  final PurchaseDetails details;

  const GooglePlayPurchaseDto(this.details);

  String get identity => details.purchaseID?.trim().isNotEmpty == true
      ? details.purchaseID!.trim()
      : details.verificationData.serverVerificationData.trim();

  StoreMembershipPurchase toEntity() {
    return StoreMembershipPurchase(
      productId: details.productID,
      purchaseIdentity: identity,
      serverVerificationData: details.verificationData.serverVerificationData
          .trim(),
      status: switch (details.status) {
        PurchaseStatus.pending => StorePurchaseStatus.pending,
        PurchaseStatus.purchased => StorePurchaseStatus.purchased,
        PurchaseStatus.restored => StorePurchaseStatus.restored,
        PurchaseStatus.canceled => StorePurchaseStatus.canceled,
        PurchaseStatus.error => StorePurchaseStatus.error,
      },
      errorCode: details.error?.code,
      errorMessage: details.error?.message,
      transactionDate: details.transactionDate == null
          ? null
          : DateTime.tryParse(details.transactionDate!),
    );
  }
}
