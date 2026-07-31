import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/repositories/admin_repository.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';

void main() {
  testWidgets('payment alert opens the reconciliable payment queue', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _PaymentReviewRepository();
    final router = GoRouter(
      initialLocation: AdminRoutePaths.dashboard,
      routes: [
        GoRoute(
          path: AdminRoutePaths.dashboard,
          builder: (context, state) =>
              const AdminShellPage(initialSection: AdminPanelSection.dashboard),
        ),
        GoRoute(
          path: AdminRoutePaths.payments,
          builder: (context, state) =>
              const AdminShellPage(initialSection: AdminPanelSection.payments),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [adminRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await _pumpAdminFrames(tester);

    final alertCallsBeforeTimer = repository.paymentReviewAlertCalls;
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(
      repository.paymentReviewAlertCalls,
      greaterThan(alertCallsBeforeTimer),
    );

    expect(find.text('2 yêu cầu thanh toán đang chờ duyệt'), findsOneWidget);
    expect(find.text('Mở thanh toán'), findsOneWidget);

    await tester.tap(find.text('Mở thanh toán'));
    await _pumpAdminFrames(tester);

    expect(
      router.routeInformationProvider.value.uri.path,
      AdminRoutePaths.payments,
    );
    expect(find.text('Đối chiếu chuyển khoản'), findsOneWidget);
    expect(
      find.textContaining('Mã giao dịch: NB12AB34CD56EF', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Khách hàng: Nguyễn Văn A', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Duyệt'), findsOneWidget);
    expect(find.text('Từ chối'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpAdminFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
  await tester.pump(const Duration(milliseconds: 220));
}

class _PaymentReviewRepository implements AdminRepository {
  int paymentReviewAlertCalls = 0;

  static const _session = AdminSession(
    userId: 'finance-admin',
    roles: [AdminRoleCode.financeAdmin],
    permissions: {AdminPermissions.wildcard},
    active: true,
  );

  @override
  bool get hasValidSession => true;

  @override
  Future<AdminSession> fetchSession() async => _session;

  @override
  Future<List<AdminDashboardMetric>> fetchDashboardSummary({
    required DateTime from,
    required DateTime to,
    required String scope,
    required String timeZone,
  }) async => const [];

  @override
  Future<AdminPaymentReviewAlert> fetchPaymentReviewAlert() async {
    paymentReviewAlertCalls++;
    return const AdminPaymentReviewAlert(pendingReviewCount: 2);
  }

  @override
  Future<List<AdminWorkItem>> fetchSectionItems({
    required AdminPanelSection section,
    required String query,
  }) async {
    if (section != AdminPanelSection.payments) return const [];
    return [
      AdminWorkItem.fromMap({
        'id': 'payment-1',
        'title': 'Gói Plus',
        'subtitle': 'Yêu cầu thanh toán thủ công',
        'status': 'pending_review',
        'section': 'payments',
        'created_at': '2026-07-31T08:00:00Z',
        'transfer_reference': 'NB12AB34CD56EF',
        'transfer_memo': 'NB12AB34CD56EF NGUYEN VAN A',
        'payer_full_name': 'Nguyễn Văn A',
        'amount_cents': 99000,
        'currency': 'VND',
        'transfer_confirmed_at': '2026-07-31T08:12:00Z',
      }),
    ];
  }

  @override
  Future<List<AdminAuditEvent>> fetchAuditEvents({
    required String query,
  }) async {
    return const [];
  }

  @override
  Future<AdminMutationResult> runMutation(AdminMutationCommand command) async {
    return const AdminMutationResult(success: true, message: 'ok');
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Stream<void> watchAuthChanges() => const Stream<void>.empty();
}
