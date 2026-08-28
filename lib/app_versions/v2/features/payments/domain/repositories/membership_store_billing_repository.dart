import '../entities/store_membership_purchase.dart';

abstract interface class MembershipStoreBillingRepository {
  Stream<StoreMembershipPurchase> get purchaseUpdates;

  Future<Storefront> loadStorefront();

  Future<bool> purchase(StoreMembershipProduct product);

  Future<void> restorePurchases();

  Future<StorePurchaseVerificationResult> verifyPurchase(
    StoreMembershipPurchase purchase,
  );

  Future<void> completePurchase(StoreMembershipPurchase purchase);
}
