import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/repositories/admin_repository.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';

void main() {
  group('AdminController permission guard', () {
    test('blocks inaccessible section before list RPC', () async {
      final repository = _FakeAdminRepository(session: _limitedSession());
      final container = _container(repository);
      addTearDown(container.dispose);

      await container.read(adminControllerProvider.future);
      await container
          .read(adminControllerProvider.notifier)
          .selectSection(AdminPanelSection.payments);

      final state = container.read(adminControllerProvider).requireValue;
      expect(state.section, AdminPanelSection.payments);
      expect(state.isPermissionDenied, isTrue);
      expect(state.deniedPermission, AdminPermissions.paymentsWrite);
      expect(repository.sectionItemCalls, isEmpty);
    });

    test(
      'loads reconciliation section through repository for full Admin',
      () async {
        final repository = _FakeAdminRepository(session: _operationsSession());
        final container = _container(repository);
        addTearDown(container.dispose);

        await container.read(adminControllerProvider.future);
        await container
            .read(adminControllerProvider.notifier)
            .selectSection(AdminPanelSection.reconciliation);

        final state = container.read(adminControllerProvider).requireValue;
        expect(state.isPermissionDenied, isFalse);
        expect(repository.sectionItemCalls, [AdminPanelSection.reconciliation]);
        expect(
          state.items.single.section,
          AdminPanelSection.reconciliation.value,
        );
      },
    );

    test('uses Vietnam timezone when loading dashboard metrics', () async {
      final repository = _FakeAdminRepository(session: _operationsSession());
      final container = _container(repository);
      addTearDown(container.dispose);

      await container.read(adminControllerProvider.future);

      expect(repository.dashboardSummaryCalls, 1);
      expect(repository.dashboardTimeZones, [
        AdminTimeDefaults.vietnamTimeZone,
      ]);
    });

    test('blocks mutation without permission before RPC', () async {
      final repository = _FakeAdminRepository(session: _limitedSession());
      final container = _container(repository);
      addTearDown(container.dispose);

      await container.read(adminControllerProvider.future);
      await container
          .read(adminControllerProvider.notifier)
          .runMutation(
            section: AdminPanelSection.payments,
            action: 'approve',
            targetId: 'payment-id',
            reason: 'Reviewed payment.',
          );

      final state = container.read(adminControllerProvider).requireValue;
      expect(repository.mutationCalls, isEmpty);
      expect(state.isPermissionDenied, isTrue);
      expect(state.deniedPermission, AdminPermissions.paymentsWrite);
      expect(
        state.lastMessage,
        'Tài khoản Admin chưa có quyền payments.write.',
      );
    });
  });
}

ProviderContainer _container(_FakeAdminRepository repository) {
  return ProviderContainer(
    overrides: [adminRepositoryProvider.overrideWithValue(repository)],
  );
}

AdminSession _operationsSession() {
  return const AdminSession(
    userId: 'operations-admin',
    roles: [AdminRoleCode.operationsAdmin],
    permissions: {AdminPermissions.wildcard},
    active: true,
  );
}

AdminSession _limitedSession() {
  return const AdminSession(
    userId: 'limited-admin',
    roles: [AdminRoleCode.operationsAdmin],
    permissions: {
      AdminPermissions.dashboardRead,
      AdminPermissions.usersWrite,
      AdminPermissions.salesWrite,
      AdminPermissions.auditRead,
    },
    active: true,
  );
}

class _FakeAdminRepository implements AdminRepository {
  final AdminSession session;
  final sectionItemCalls = <AdminPanelSection>[];
  final mutationCalls = <AdminMutationCommand>[];
  final dashboardTimeZones = <String>[];
  int dashboardSummaryCalls = 0;
  int auditEventCalls = 0;
  int signOutCalls = 0;

  _FakeAdminRepository({required this.session});

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }

  @override
  Future<AdminSession> fetchSession() async => session;

  @override
  Future<List<AdminDashboardMetric>> fetchDashboardSummary({
    required DateTime from,
    required DateTime to,
    required String scope,
    required String timeZone,
  }) async {
    dashboardSummaryCalls++;
    dashboardTimeZones.add(timeZone);
    return const [
      AdminDashboardMetric(
        key: 'users_total',
        label: 'Người dùng',
        value: 1,
        status: 'ready',
        targetSection: 'users',
      ),
    ];
  }

  @override
  Future<List<AdminWorkItem>> fetchSectionItems({
    required AdminPanelSection section,
    required String query,
  }) async {
    sectionItemCalls.add(section);
    return [
      AdminWorkItem(
        id: '${section.value}-1',
        title: 'Item',
        subtitle: query,
        status: 'pending',
        section: section.value,
      ),
    ];
  }

  @override
  Future<List<AdminAuditEvent>> fetchAuditEvents({
    required String query,
  }) async {
    auditEventCalls++;
    return const [];
  }

  @override
  Future<AdminMutationResult> runMutation(AdminMutationCommand command) async {
    mutationCalls.add(command);
    return const AdminMutationResult(success: true, message: 'ok');
  }
}
