enum StoreMembershipPlan {
  plus,
  familyPlus;

  String get code => switch (this) {
    StoreMembershipPlan.plus => 'plus',
    StoreMembershipPlan.familyPlus => 'family_plus',
  };

  String get label => switch (this) {
    StoreMembershipPlan.plus => 'Plus',
    StoreMembershipPlan.familyPlus => 'FamilyPlus',
  };
}

enum StoreBillingCycle {
  monthly,
  yearly;

  String get code => switch (this) {
    StoreBillingCycle.monthly => 'monthly',
    StoreBillingCycle.yearly => 'yearly',
  };

  String get label => switch (this) {
    StoreBillingCycle.monthly => 'Hằng tháng',
    StoreBillingCycle.yearly => 'Hằng năm',
  };
}

/// Product IDs are deliberately centralized. They are public Play product
/// identifiers, not credentials. Create the matching subscriptions in Play
/// Console before an internal-track purchase test.
class StoreMembershipProduct {
  static const androidPackageName = 'com.nanobioai.app';

  static const plusMonthly = StoreMembershipProduct._(
    id: 'nanobio_plus_monthly',
    plan: StoreMembershipPlan.plus,
    cycle: StoreBillingCycle.monthly,
  );
  static const plusYearly = StoreMembershipProduct._(
    id: 'nanobio_plus_yearly',
    plan: StoreMembershipPlan.plus,
    cycle: StoreBillingCycle.yearly,
  );
  static const familyPlusMonthly = StoreMembershipProduct._(
    id: 'nanobio_family_plus_monthly',
    plan: StoreMembershipPlan.familyPlus,
    cycle: StoreBillingCycle.monthly,
  );
  static const familyPlusYearly = StoreMembershipProduct._(
    id: 'nanobio_family_plus_yearly',
    plan: StoreMembershipPlan.familyPlus,
    cycle: StoreBillingCycle.yearly,
  );

  static const values = <StoreMembershipProduct>[
    plusMonthly,
    plusYearly,
    familyPlusMonthly,
    familyPlusYearly,
  ];

  final String id;
  final StoreMembershipPlan plan;
  final StoreBillingCycle cycle;

  const StoreMembershipProduct._({
    required this.id,
    required this.plan,
    required this.cycle,
  });

  static StoreMembershipProduct? fromId(String id) {
    final normalized = id.trim();
    for (final product in values) {
      if (product.id == normalized) return product;
    }
    return null;
  }

  static StoreMembershipProduct? fromSelection({
    required String planCode,
    required String billingCycle,
  }) {
    final plan = switch (planCode.trim()) {
      'plus' => StoreMembershipPlan.plus,
      'family_plus' => StoreMembershipPlan.familyPlus,
      _ => null,
    };
    final cycle = switch (billingCycle.trim()) {
      'monthly' => StoreBillingCycle.monthly,
      'yearly' => StoreBillingCycle.yearly,
      _ => null,
    };
    if (plan == null || cycle == null) return null;
    return values.firstWhere(
      (item) => item.plan == plan && item.cycle == cycle,
    );
  }
}

class StoreProductDetails {
  final StoreMembershipProduct product;
  final String title;
  final String description;
  final String displayPrice;
  final double rawPrice;
  final String currencyCode;

  const StoreProductDetails({
    required this.product,
    required this.title,
    required this.description,
    required this.displayPrice,
    required this.rawPrice,
    required this.currencyCode,
  });
}

class Storefront {
  final bool isAvailable;
  final List<StoreProductDetails> products;
  final List<String> missingProductIds;

  const Storefront({
    required this.isAvailable,
    this.products = const [],
    this.missingProductIds = const [],
  });

  StoreProductDetails? productFor(StoreMembershipProduct product) {
    for (final details in products) {
      if (details.product.id == product.id) return details;
    }
    return null;
  }
}

enum StorePurchaseStatus { pending, purchased, restored, canceled, error }

class StoreMembershipPurchase {
  final String productId;
  final String purchaseIdentity;
  final String serverVerificationData;
  final StorePurchaseStatus status;
  final String? errorCode;
  final String? errorMessage;
  final DateTime? transactionDate;

  const StoreMembershipPurchase({
    required this.productId,
    required this.purchaseIdentity,
    required this.serverVerificationData,
    required this.status,
    this.errorCode,
    this.errorMessage,
    this.transactionDate,
  });

  StoreMembershipProduct? get product =>
      StoreMembershipProduct.fromId(productId);
}

enum StoreVerificationStatus { verified, pending, rejected }

class StorePurchaseVerificationResult {
  final StoreVerificationStatus status;
  final String? planCode;
  final DateTime? expiresAt;
  final bool retryable;
  final String message;

  const StorePurchaseVerificationResult({
    required this.status,
    this.planCode,
    this.expiresAt,
    this.retryable = false,
    this.message = '',
  });

  bool get isVerified => status == StoreVerificationStatus.verified;
  bool get isPending => status == StoreVerificationStatus.pending;
}

enum MembershipStoreBillingStatus {
  initial,
  loading,
  ready,
  unavailable,
  purchasing,
  pending,
  restoring,
  awaitingVerification,
  success,
  canceled,
  error,
}

class MembershipStoreBillingState {
  final MembershipStoreBillingStatus status;
  final Storefront? storefront;
  final String? selectedProductId;
  final String? message;
  final bool retryable;

  const MembershipStoreBillingState({
    this.status = MembershipStoreBillingStatus.initial,
    this.storefront,
    this.selectedProductId,
    this.message,
    this.retryable = false,
  });

  MembershipStoreBillingState copyWith({
    MembershipStoreBillingStatus? status,
    Object? storefront = _unchanged,
    Object? selectedProductId = _unchanged,
    Object? message = _unchanged,
    bool? retryable,
  }) {
    return MembershipStoreBillingState(
      status: status ?? this.status,
      storefront: identical(storefront, _unchanged)
          ? this.storefront
          : storefront as Storefront?,
      selectedProductId: identical(selectedProductId, _unchanged)
          ? this.selectedProductId
          : selectedProductId as String?,
      message: identical(message, _unchanged)
          ? this.message
          : message as String?,
      retryable: retryable ?? this.retryable,
    );
  }

  static const _unchanged = Object();
}

class MembershipStoreBillingException implements Exception {
  final String code;
  final String safeMessage;
  final bool retryable;

  const MembershipStoreBillingException(
    this.code,
    this.safeMessage, {
    this.retryable = false,
  });

  const MembershipStoreBillingException.authRequired()
    : this('AUTH_REQUIRED', 'Bạn cần đăng nhập để tiếp tục.', retryable: false);

  const MembershipStoreBillingException.storeUnavailable()
    : this(
        'STORE_UNAVAILABLE',
        'Google Play chưa sẵn sàng trên thiết bị này. Bạn hãy thử lại sau.',
        retryable: true,
      );

  const MembershipStoreBillingException.productUnavailable()
    : this(
        'PRODUCT_UNAVAILABLE',
        'Gói này chưa sẵn sàng để đăng ký. Bạn hãy thử lại sau.',
        retryable: true,
      );

  @override
  String toString() => '$code: $safeMessage';
}
