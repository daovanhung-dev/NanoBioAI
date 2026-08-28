import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../domain/entities/store_membership_purchase.dart';
import '../models/google_play_purchase_dto.dart';

abstract interface class MembershipStoreBillingDatasource {
  Stream<GooglePlayPurchaseDto> get purchaseUpdates;

  Future<bool> isAvailable();

  Future<List<GooglePlayProductDetailsDto>> queryProducts(
    Set<String> productIds,
  );

  Future<bool> buy(String productId);

  Future<void> restorePurchases();

  Future<void> completePurchase(String purchaseIdentity);
}

class GooglePlayBillingDatasource implements MembershipStoreBillingDatasource {
  final InAppPurchase _billing;
  final Map<String, PurchaseDetails> _pendingPurchases = {};
  final Map<String, ProductDetails> _products = {};

  GooglePlayBillingDatasource({InAppPurchase? billing})
    : _billing = billing ?? InAppPurchase.instance;

  @override
  Stream<GooglePlayPurchaseDto> get purchaseUpdates {
    return _billing.purchaseStream.expand((purchases) {
      final result = <GooglePlayPurchaseDto>[];
      for (final purchase in purchases) {
        final dto = GooglePlayPurchaseDto(purchase);
        _pendingPurchases[dto.identity] = purchase;
        result.add(dto);
      }
      return result;
    });
  }

  @override
  Future<bool> isAvailable() => _billing.isAvailable();

  @override
  Future<List<GooglePlayProductDetailsDto>> queryProducts(
    Set<String> productIds,
  ) async {
    final response = await _billing.queryProductDetails(productIds);
    _products
      ..clear()
      ..addEntries(
        response.productDetails.map((details) => MapEntry(details.id, details)),
      );

    return [
      for (final details in response.productDetails)
        if (StoreMembershipProduct.fromId(details.id) case final product?)
          GooglePlayProductDetailsDto(
            platformDetails: details,
            product: product,
          ),
    ];
  }

  @override
  Future<bool> buy(String productId) async {
    final product = _products[productId];
    if (product == null) {
      throw const MembershipStoreBillingException.productUnavailable();
    }
    return _billing.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  @override
  Future<void> restorePurchases() => _billing.restorePurchases();

  @override
  Future<void> completePurchase(String purchaseIdentity) async {
    final purchase = _pendingPurchases.remove(purchaseIdentity);
    if (purchase == null || !purchase.pendingCompletePurchase) return;
    await _billing.completePurchase(purchase);
  }
}
