import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_dependencies.dart';

class AdminMembershipReviewState {
  final AdminSession session;
  final List<AdminWorkItem> payments;
  final String query;
  final String? message;

  const AdminMembershipReviewState({
    required this.session,
    required this.payments,
    required this.query,
    this.message,
  });

  bool get canReview => session.canReviewMembershipPayments;
}

class AdminMembershipController extends AsyncNotifier<AdminMembershipReviewState> {
  @override
  Future<AdminMembershipReviewState> build() => _load('');

  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(query.trim()));
  }

  Future<void> refresh() async {
    final query = state.asData?.value.query ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(query));
  }

  Future<void> reviewPayment({
    required String paymentId,
    required String decision,
    required String reason,
    required bool transferVerified,
  }) async {
    final current = state.asData?.value ?? await _load('');
    if (!current.canReview) {
      throw StateError('Chỉ Finance Admin hoặc Super Admin được duyệt thanh toán.');
    }
    if (decision == 'approve' && !transferVerified) {
      throw StateError('Cần xác nhận đã đối chiếu giao dịch Vietcombank.');
    }
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw StateError('Vui lòng nhập lý do cho quyết định này.');
    }
    await ref.read(adminRepositoryProvider).runMutation(
      AdminMutationCommand(
        section: AdminPanelSection.payments,
        action: decision,
        targetId: paymentId,
        reason: trimmedReason,
        idempotencyKey:
            'membership-$decision-$paymentId-${DateTime.now().microsecondsSinceEpoch}',
        payload: {'transfer_verified': transferVerified},
      ),
    );
    final next = await _load(current.query);
    state = AsyncData(
      AdminMembershipReviewState(
        session: next.session,
        payments: next.payments,
        query: next.query,
        message: decision == 'approve'
            ? 'Đã duyệt nâng cấp gói thành viên.'
            : 'Đã từ chối yêu cầu nâng cấp gói.',
      ),
    );
  }

  Future<AdminMembershipReviewState> _load(String query) async {
    final repository = ref.read(adminRepositoryProvider);
    final session = await repository.fetchSession();
    if (!session.isAdmin || !session.canReviewMembershipPayments) {
      return AdminMembershipReviewState(
        session: session,
        payments: const [],
        query: query,
      );
    }
    final payments = await repository.fetchSectionItems(
      section: AdminPanelSection.payments,
      query: query,
    );
    return AdminMembershipReviewState(
      session: session,
      payments: payments,
      query: query,
    );
  }
}
