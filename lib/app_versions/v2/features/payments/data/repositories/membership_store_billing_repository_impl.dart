import '../../domain/entities/store_membership_purchase.dart';
import '../../domain/repositories/membership_store_billing_repository.dart';
import '../datasources/google_play_billing_datasource.dart';
import '../datasources/membership_store_purchase_remote_datasource.dart';

class MembershipStoreBillingRepositoryImpl
    implements MembershipStoreBillingRepository {
  final MembershipStoreBillingDatasource billingDatasource;
  final MembershipStorePurchaseRemoteDatasource verificationDatasource;

  const MembershipStoreBillingRepositoryImpl({
    required this.billingDatasource,
    required this.verificationDatasource,
  });

  @override
  Stream<StoreMembershipPurchase> get purchaseUpdates {
    return billingDatasource.purchaseUpdates.map((dto) => dto.toEntity());
  }

  @override
  Future<Storefront> loadStorefront() async {
    final available = await billingDatasource.isAvailable();
    if (!available) {
      throw const MembershipStoreBillingException.storeUnavailable();
    }
    final details = await billingDatasource.queryProducts(
      StoreMembershipProduct.values.map((product) => product.id).toSet(),
    );
    final knownIds = details.map((item) => item.product.id).toSet();
    return Storefront(
      isAvailable: true,
      products: details.map((item) => item.toEntity()).toList(growable: false),
      missingProductIds: [
        for (final product in StoreMembershipProduct.values)
          if (!knownIds.contains(product.id)) product.id,
      ],
    );
  }

  @override
  Future<bool> purchase(StoreMembershipProduct product) {
    return billingDatasource.buy(product.id);
  }

  @override
  Future<void> restorePurchases() => billingDatasource.restorePurchases();

  @override
  Future<StorePurchaseVerificationResult> verifyPurchase(
    StoreMembershipPurchase purchase,
  ) {
    if (purchase.product == null || purchase.serverVerificationData.isEmpty) {
      throw const MembershipStoreBillingException(
        'INVALID_PURCHASE',
        'Giao dịch chưa có đủ thông tin để xác minh.',
      );
    }
    return verificationDatasource.verifyPurchase(purchase);
  }

  @override
  Future<void> completePurchase(StoreMembershipPurchase purchase) {
    return billingDatasource.completePurchase(purchase.purchaseIdentity);
  }
}
