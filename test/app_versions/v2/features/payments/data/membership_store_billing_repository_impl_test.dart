import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:nano_app/app_versions/v2/features/payments/data/datasources/google_play_billing_datasource.dart';
import 'package:nano_app/app_versions/v2/features/payments/data/datasources/membership_store_purchase_remote_datasource.dart';
import 'package:nano_app/app_versions/v2/features/payments/data/models/google_play_purchase_dto.dart';
import 'package:nano_app/app_versions/v2/features/payments/data/repositories/membership_store_billing_repository_impl.dart';
import 'package:nano_app/app_versions/v2/features/payments/domain/entities/store_membership_purchase.dart';

void main() {
  test('loads only known Play products and reports missing IDs', () async {
    final billing = _FakeBillingDatasource(
      products: [
        GooglePlayProductDetailsDto(
          platformDetails: _product(StoreMembershipProduct.plusMonthly.id),
          product: StoreMembershipProduct.plusMonthly,
        ),
      ],
    );
    final repository = MembershipStoreBillingRepositoryImpl(
      billingDatasource: billing,
      verificationDatasource: _FakeVerificationDatasource(),
    );

    final storefront = await repository.loadStorefront();

    expect(storefront.isAvailable, isTrue);
    expect(storefront.products.single.displayPrice, '₫99,000');
    expect(
      storefront.missingProductIds,
      contains(StoreMembershipProduct.plusYearly.id),
    );
  });

  test(
    'purchase updates expose server verification data but never grant locally',
    () async {
      final billing = _FakeBillingDatasource();
      final repository = MembershipStoreBillingRepositoryImpl(
        billingDatasource: billing,
        verificationDatasource: _FakeVerificationDatasource(),
      );
      final future = repository.purchaseUpdates.first;

      billing.emit(_purchase(StoreMembershipProduct.plusMonthly.id));
      final purchase = await future;

      expect(purchase.status, StorePurchaseStatus.purchased);
      expect(purchase.serverVerificationData, 'server-token');
      expect(purchase.product, StoreMembershipProduct.plusMonthly);
    },
  );

  test('verification delegates to trusted remote datasource', () async {
    final verification = _FakeVerificationDatasource();
    final repository = MembershipStoreBillingRepositoryImpl(
      billingDatasource: _FakeBillingDatasource(),
      verificationDatasource: verification,
    );
    final purchase = _purchase(
      StoreMembershipProduct.familyPlusYearly.id,
    ).toEntity();

    final result = await repository.verifyPurchase(purchase);

    expect(result.isVerified, isTrue);
    expect(
      verification.lastPurchase?.productId,
      StoreMembershipProduct.familyPlusYearly.id,
    );
  });
}

ProductDetails _product(String id) => ProductDetails(
  id: id,
  title: 'NanoBio ${id.replaceAll('_', ' ')}',
  description: 'Gói chăm sóc sức khỏe',
  price: '₫99,000',
  rawPrice: 99000,
  currencyCode: 'VND',
);

GooglePlayPurchaseDto _purchase(
  String productId, {
  PurchaseStatus status = PurchaseStatus.purchased,
}) {
  return GooglePlayPurchaseDto(
    PurchaseDetails(
      purchaseID: 'order-1',
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'server-token',
        source: 'Google Play',
      ),
      transactionDate: '1764547200000',
      status: status,
    ),
  );
}

class _FakeBillingDatasource implements MembershipStoreBillingDatasource {
  final StreamController<GooglePlayPurchaseDto> _updates =
      StreamController.broadcast();
  final List<GooglePlayProductDetailsDto> products;

  _FakeBillingDatasource({this.products = const []});

  void emit(GooglePlayPurchaseDto purchase) => _updates.add(purchase);

  @override
  Stream<GooglePlayPurchaseDto> get purchaseUpdates => _updates.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<GooglePlayProductDetailsDto>> queryProducts(
    Set<String> productIds,
  ) async => products;

  @override
  Future<bool> buy(String productId) async => true;

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<void> completePurchase(String purchaseIdentity) async {}
}

class _FakeVerificationDatasource
    implements MembershipStorePurchaseRemoteDatasource {
  StoreMembershipPurchase? lastPurchase;

  @override
  Future<StorePurchaseVerificationResult> verifyPurchase(
    StoreMembershipPurchase purchase,
  ) async {
    lastPurchase = purchase;
    return const StorePurchaseVerificationResult(
      status: StoreVerificationStatus.verified,
      planCode: 'family_plus',
    );
  }
}
