import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_dependencies.dart';

class AdminSalesState {
  final AdminSession session;
  final List<AdminWorkItem> saleReviews;
  final List<AdminWorkItem> payouts;
  final String saleQuery;
  final String payoutQuery;
  final String? message;

  const AdminSalesState({
    required this.session,
    required this.saleReviews,
    required this.payouts,
    required this.saleQuery,
    required this.payoutQuery,
    this.message,
  });

  bool get canManageSales => session.hasPermission(AdminPermissions.salesWrite);
}

class AdminSalesController extends AsyncNotifier<AdminSalesState> {
  @override
  Future<AdminSalesState> build() => _load(saleQuery: '', payoutQuery: '');

  Future<void> searchSales(String query) async {
    final current = state.asData?.value;
    final normalized = query.trim();
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _load(
        saleQuery: normalized,
        payoutQuery: current?.payoutQuery ?? '',
      ),
    );
  }

  Future<void> searchPayouts(String query) async {
    final current = state.asData?.value;
    final normalized = query.trim();
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _load(
        saleQuery: current?.saleQuery ?? '',
        payoutQuery: normalized,
      ),
    );
  }

  Future<void> refresh() async {
    final current = state.asData?.value;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _load(
        saleQuery: current?.saleQuery ?? '',
        payoutQuery: current?.payoutQuery ?? '',
      ),
    );
  }

  Future<void> reviewSale({
    required String userId,
    required String decision,
    required String reason,
  }) async {
    final current = state.asData?.value ??
        await _load(saleQuery: '', payoutQuery: '');
    _assertPermission(current);
    await ref.read(adminRepositoryProvider).runMutation(
      AdminMutationCommand(
        section: AdminPanelSection.sales,
        action: decision,
        targetId: userId,
        reason: _requiredReason(reason),
        idempotencyKey: _idempotency('sale-$decision', userId),
      ),
    );
    await _refreshWithMessage('Đã cập nhật hồ sơ Sale.');
  }

  Future<void> reviewPayout({
    required String conversionId,
    required String decision,
    required String reason,
    String? paymentProofPath,
  }) async {
    final current = state.asData?.value ??
        await _load(saleQuery: '', payoutQuery: '');
    _assertPermission(current);
    if (decision == 'mark_paid' &&
        (paymentProofPath == null || paymentProofPath.trim().isEmpty)) {
      throw StateError('Cần ảnh xác nhận chuyển tiền trước khi đánh dấu đã chi trả.');
    }
    await ref.read(adminRepositoryProvider).runMutation(
      AdminMutationCommand(
        section: AdminPanelSection.saleConversions,
        action: decision,
        targetId: conversionId,
        reason: _requiredReason(reason),
        idempotencyKey: _idempotency('sale-payout-$decision', conversionId),
        payload: {
          if (paymentProofPath != null) 'payment_proof_path': paymentProofPath,
        },
      ),
    );
    await _refreshWithMessage(
      decision == 'mark_paid' ? 'Đã xác nhận chi trả cho Sale.' : 'Đã cập nhật yêu cầu thanh toán Sale.',
    );
  }

  Future<AdminSalesState> _load({
    required String saleQuery,
    required String payoutQuery,
  }) async {
    final repository = ref.read(adminRepositoryProvider);
    final session = await repository.fetchSession();
    if (!session.isAdmin || !session.hasPermission(AdminPermissions.salesWrite)) {
      return AdminSalesState(
        session: session,
        saleReviews: const [],
        payouts: const [],
        saleQuery: saleQuery,
        payoutQuery: payoutQuery,
      );
    }
    final reviews = await repository.fetchSectionItems(
      section: AdminPanelSection.sales,
      query: saleQuery,
    );
    final payouts = await repository.fetchSectionItems(
      section: AdminPanelSection.saleConversions,
      query: payoutQuery,
    );
    return AdminSalesState(
      session: session,
      saleReviews: reviews,
      payouts: payouts,
      saleQuery: saleQuery,
      payoutQuery: payoutQuery,
    );
  }

  Future<void> _refreshWithMessage(String message) async {
    final current = state.asData?.value;
    final next = await _load(
      saleQuery: current?.saleQuery ?? '',
      payoutQuery: current?.payoutQuery ?? '',
    );
    state = AsyncData(
      AdminSalesState(
        session: next.session,
        saleReviews: next.saleReviews,
        payouts: next.payouts,
        saleQuery: next.saleQuery,
        payoutQuery: next.payoutQuery,
        message: message,
      ),
    );
  }

  void _assertPermission(AdminSalesState state) {
    if (!state.canManageSales) {
      throw StateError('Tài khoản quản trị chưa được phép xử lý Sale.');
    }
  }

  String _requiredReason(String value) {
    final result = value.trim();
    if (result.isEmpty) throw StateError('Vui lòng nhập lý do cho thao tác này.');
    return result;
  }

  String _idempotency(String action, String target) {
    return '$action-$target-${DateTime.now().microsecondsSinceEpoch}';
  }
}
