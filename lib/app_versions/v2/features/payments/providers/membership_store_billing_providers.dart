import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/providers/membership_entitlement_providers.dart';

import '../data/datasources/google_play_billing_datasource.dart';
import '../data/datasources/membership_store_purchase_remote_datasource.dart';
import '../data/repositories/membership_store_billing_repository_impl.dart';
import '../domain/entities/store_membership_purchase.dart';
import '../domain/repositories/membership_store_billing_repository.dart';

final membershipStoreBillingDatasourceProvider =
    Provider<MembershipStoreBillingDatasource>((ref) {
      return GooglePlayBillingDatasource();
    });

final membershipStorePurchaseRemoteDatasourceProvider =
    Provider<MembershipStorePurchaseRemoteDatasource>((ref) {
      return const SupabaseMembershipStorePurchaseRemoteDatasource();
    });

final membershipStoreBillingRepositoryProvider =
    Provider<MembershipStoreBillingRepository>((ref) {
      return MembershipStoreBillingRepositoryImpl(
        billingDatasource: ref.watch(membershipStoreBillingDatasourceProvider),
        verificationDatasource: ref.watch(
          membershipStorePurchaseRemoteDatasourceProvider,
        ),
      );
    });

final membershipStoreBillingControllerProvider =
    NotifierProvider<
      MembershipStoreBillingController,
      MembershipStoreBillingState
    >(MembershipStoreBillingController.new);

class MembershipStoreBillingController
    extends Notifier<MembershipStoreBillingState> {
  StreamSubscription<StoreMembershipPurchase>? _purchaseSubscription;
  final Set<String> _verifiedPurchaseIdentities = {};

  MembershipStoreBillingRepository get _repository =>
      ref.read(membershipStoreBillingRepositoryProvider);

  @override
  MembershipStoreBillingState build() {
    _purchaseSubscription = _repository.purchaseUpdates.listen(
      _handlePurchase,
      onError: (_, __) {
        state = state.copyWith(
          status: MembershipStoreBillingStatus.error,
          message: 'Chưa nhận được cập nhật giao dịch. Bạn hãy thử lại.',
          retryable: true,
        );
      },
    );
    ref.onDispose(() => _purchaseSubscription?.cancel());
    // A Notifier's state is not initialized until `build` returns. Schedule
    // the first storefront load after that point so async failures update a
    // valid state instead of reading an uninitialized provider.
    unawaited(Future<void>.microtask(loadStorefront));
    return const MembershipStoreBillingState();
  }

  Future<void> loadStorefront() async {
    state = state.copyWith(
      status: MembershipStoreBillingStatus.loading,
      message: null,
      retryable: false,
    );
    try {
      final storefront = await _repository.loadStorefront();
      state = state.copyWith(
        status: MembershipStoreBillingStatus.ready,
        storefront: storefront,
      );
    } on MembershipStoreBillingException catch (error) {
      state = state.copyWith(
        status: error.code == 'STORE_UNAVAILABLE'
            ? MembershipStoreBillingStatus.unavailable
            : MembershipStoreBillingStatus.error,
        message: error.safeMessage,
        retryable: error.retryable,
      );
    } catch (_) {
      state = state.copyWith(
        status: MembershipStoreBillingStatus.error,
        message: 'Chưa tải được các gói đăng ký. Bạn hãy thử lại.',
        retryable: true,
      );
    }
  }

  Future<void> purchase(StoreMembershipProduct product) async {
    if (state.status == MembershipStoreBillingStatus.purchasing ||
        state.status == MembershipStoreBillingStatus.awaitingVerification) {
      return;
    }
    if (state.storefront?.productFor(product) == null) {
      state = state.copyWith(
        status: MembershipStoreBillingStatus.error,
        message: 'Gói này chưa sẵn sàng để đăng ký. Bạn hãy thử lại sau.',
        retryable: true,
      );
      return;
    }
    state = state.copyWith(
      status: MembershipStoreBillingStatus.purchasing,
      selectedProductId: product.id,
      message: null,
      retryable: false,
    );
    try {
      final launched = await _repository.purchase(product);
      if (!launched) {
        state = state.copyWith(
          status: MembershipStoreBillingStatus.error,
          message:
              'Google Play chưa mở được màn hình đăng ký. Bạn hãy thử lại.',
          retryable: true,
        );
      }
    } on MembershipStoreBillingException catch (error) {
      state = state.copyWith(
        status: MembershipStoreBillingStatus.error,
        message: error.safeMessage,
        retryable: error.retryable,
      );
    } catch (_) {
      state = state.copyWith(
        status: MembershipStoreBillingStatus.error,
        message: 'Chưa thể bắt đầu đăng ký. Bạn hãy thử lại sau.',
        retryable: true,
      );
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(
      status: MembershipStoreBillingStatus.restoring,
      message: null,
      retryable: false,
    );
    try {
      await _repository.restorePurchases();
      state = state.copyWith(
        status: MembershipStoreBillingStatus.awaitingVerification,
        message: 'Đang kiểm tra các gói bạn đã đăng ký…',
      );
    } catch (_) {
      state = state.copyWith(
        status: MembershipStoreBillingStatus.error,
        message: 'Chưa khôi phục được giao dịch. Bạn hãy thử lại.',
        retryable: true,
      );
    }
  }

  Future<void> _handlePurchase(StoreMembershipPurchase purchase) async {
    if (purchase.status == StorePurchaseStatus.pending) {
      state = state.copyWith(
        status: MembershipStoreBillingStatus.pending,
        selectedProductId: purchase.productId,
        message: 'Giao dịch đang chờ Google Play xử lý.',
      );
      return;
    }
    if (purchase.status == StorePurchaseStatus.canceled) {
      state = state.copyWith(
        status: MembershipStoreBillingStatus.canceled,
        message: 'Bạn đã hủy giao dịch. Gói chưa được thay đổi.',
      );
      return;
    }
    if (purchase.status == StorePurchaseStatus.error) {
      state = state.copyWith(
        status: MembershipStoreBillingStatus.error,
        message: 'Google Play chưa hoàn tất giao dịch. Bạn hãy thử lại.',
        retryable: true,
      );
      return;
    }

    final product = purchase.product;
    if (product == null) {
      state = state.copyWith(
        status: MembershipStoreBillingStatus.error,
        message: 'Gói đăng ký không hợp lệ. Bạn hãy liên hệ hỗ trợ.',
      );
      return;
    }
    if (_verifiedPurchaseIdentities.contains(purchase.purchaseIdentity)) return;

    state = state.copyWith(
      status: MembershipStoreBillingStatus.awaitingVerification,
      selectedProductId: product.id,
      message: 'Đang xác minh giao dịch để cập nhật gói của bạn…',
      retryable: false,
    );
    try {
      final result = await _repository.verifyPurchase(purchase);
      if (result.isVerified) {
        await _repository.completePurchase(purchase);
        _verifiedPurchaseIdentities.add(purchase.purchaseIdentity);
        ref.invalidate(effectiveAccessProvider);
        state = state.copyWith(
          status: MembershipStoreBillingStatus.success,
          message: 'Đã xác minh giao dịch. Gói của bạn sẽ được cập nhật ngay.',
          retryable: false,
        );
      } else if (result.isPending) {
        state = state.copyWith(
          status: MembershipStoreBillingStatus.awaitingVerification,
          message: 'Giao dịch đang chờ xác minh. Bạn hãy làm mới sau ít phút.',
          retryable: true,
        );
      } else {
        if (!result.retryable) await _repository.completePurchase(purchase);
        state = state.copyWith(
          status: MembershipStoreBillingStatus.error,
          message: result.message.isEmpty
              ? 'Giao dịch chưa được xác minh nên gói chưa thay đổi.'
              : result.message,
          retryable: result.retryable,
        );
      }
    } on MembershipStoreBillingException catch (error) {
      state = state.copyWith(
        status: MembershipStoreBillingStatus.error,
        message: error.safeMessage,
        retryable: error.retryable,
      );
    } catch (_) {
      state = state.copyWith(
        status: MembershipStoreBillingStatus.error,
        message: 'Chưa xác minh được giao dịch. Bạn hãy thử lại sau.',
        retryable: true,
      );
    }
  }
}
