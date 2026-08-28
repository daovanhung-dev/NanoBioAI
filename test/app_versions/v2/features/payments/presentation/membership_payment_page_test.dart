import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/payments/domain/entities/store_membership_purchase.dart';
import 'package:nano_app/app_versions/v2/features/payments/domain/repositories/membership_store_billing_repository.dart';
import 'package:nano_app/app_versions/v2/features/payments/presentation/pages/membership_payment_page.dart';
import 'package:nano_app/app_versions/v2/features/payments/providers/membership_store_billing_providers.dart';

void main() {
  testWidgets('normalizes the selected plan and renders Play product details', (
    tester,
  ) async {
    final repository = _FakeStoreBillingRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      _TestApp(
        repository: repository,
        page: const MembershipPaymentPage(initialPlanCode: 'family_plus'),
      ),
    );
    await tester.pumpAndSettle();

    final selectors = tester.widgetList<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(selectors.first.initialValue, 'family_plus');
    expect(selectors.last.initialValue, 'monthly');
    expect(find.text('FamilyPlus tháng'), findsOneWidget);
    expect(find.text('129.000 đ'), findsOneWidget);
    expect(find.textContaining('Google Play'), findsWidgets);
    expect(find.textContaining('VietQR'), findsNothing);
  });

  testWidgets(
    'launches purchase and completes only after trusted verification',
    (tester) async {
      final repository = _FakeStoreBillingRepository();
      addTearDown(repository.dispose);

      await tester.pumpWidget(_TestApp(repository: repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đăng ký 99.000 đ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(repository.purchaseCallCount, 1);
      expect(repository.lastProduct, StoreMembershipProduct.plusMonthly);
      expect(repository.completeCallCount, 0);

      repository.emit(
        const StoreMembershipPurchase(
          productId: 'nanobio_plus_monthly',
          purchaseIdentity: 'order-1',
          serverVerificationData: 'opaque-token',
          status: StorePurchaseStatus.purchased,
        ),
      );
      await tester.pump();

      expect(repository.verifyCallCount, 1);
      expect(repository.completeCallCount, 1);
      expect(find.textContaining('Đã xác minh giao dịch'), findsOneWidget);
    },
  );

  testWidgets('keeps a pending Play transaction unacknowledged', (
    tester,
  ) async {
    final repository = _FakeStoreBillingRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(_TestApp(repository: repository));
    await tester.pumpAndSettle();

    repository.emit(
      const StoreMembershipPurchase(
        productId: 'nanobio_plus_monthly',
        purchaseIdentity: 'order-pending',
        serverVerificationData: 'opaque-token',
        status: StorePurchaseStatus.pending,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('đang chờ Google Play'), findsOneWidget);
    expect(repository.verifyCallCount, 0);
    expect(repository.completeCallCount, 0);
  });
}

class _TestApp extends StatelessWidget {
  final MembershipStoreBillingRepository repository;
  final MembershipPaymentPage page;

  const _TestApp({
    required this.repository,
    this.page = const MembershipPaymentPage(),
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        membershipStoreBillingRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(home: page),
    );
  }
}

class _FakeStoreBillingRepository implements MembershipStoreBillingRepository {
  final StreamController<StoreMembershipPurchase> _updates =
      StreamController<StoreMembershipPurchase>.broadcast();
  int purchaseCallCount = 0;
  int verifyCallCount = 0;
  int completeCallCount = 0;
  StoreMembershipProduct? lastProduct;

  final Storefront storefront = Storefront(
    isAvailable: true,
    products: [
      StoreProductDetails(
        product: StoreMembershipProduct.plusMonthly,
        title: 'Plus tháng',
        description: 'Trợ lý sức khỏe nâng cao',
        displayPrice: '99.000 đ',
        rawPrice: 99000,
        currencyCode: 'VND',
      ),
      StoreProductDetails(
        product: StoreMembershipProduct.plusYearly,
        title: 'Plus năm',
        description: 'Trợ lý sức khỏe nâng cao',
        displayPrice: '999.000 đ',
        rawPrice: 999000,
        currencyCode: 'VND',
      ),
      StoreProductDetails(
        product: StoreMembershipProduct.familyPlusMonthly,
        title: 'FamilyPlus tháng',
        description: 'Chia sẻ cho gia đình',
        displayPrice: '129.000 đ',
        rawPrice: 129000,
        currencyCode: 'VND',
      ),
      StoreProductDetails(
        product: StoreMembershipProduct.familyPlusYearly,
        title: 'FamilyPlus năm',
        description: 'Chia sẻ cho gia đình',
        displayPrice: '1.290.000 đ',
        rawPrice: 1290000,
        currencyCode: 'VND',
      ),
    ],
  );

  @override
  Stream<StoreMembershipPurchase> get purchaseUpdates => _updates.stream;

  @override
  Future<Storefront> loadStorefront() async => storefront;

  @override
  Future<bool> purchase(StoreMembershipProduct product) async {
    purchaseCallCount++;
    lastProduct = product;
    return true;
  }

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<StorePurchaseVerificationResult> verifyPurchase(
    StoreMembershipPurchase purchase,
  ) async {
    verifyCallCount++;
    return const StorePurchaseVerificationResult(
      status: StoreVerificationStatus.verified,
      planCode: 'plus',
    );
  }

  @override
  Future<void> completePurchase(StoreMembershipPurchase purchase) async {
    completeCallCount++;
  }

  void emit(StoreMembershipPurchase purchase) => _updates.add(purchase);

  Future<void> dispose() => _updates.close();
}
