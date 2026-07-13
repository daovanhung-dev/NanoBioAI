import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_access_state.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/repositories/admin_repository.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/core/config/auth_backend_availability.dart';

void main() {
  group('AdminAccessController', () {
    test('restores an active Admin session', () async {
      final repository = _AccessRepository(
        session: const AdminSession(
          userId: 'admin-1',
          roles: [AdminRoleCode.superAdmin],
          permissions: {AdminPermissions.wildcard},
          active: true,
        ),
      );
      final container = _container(repository);
      addTearDown(container.dispose);

      final state = await container.read(adminAccessControllerProvider.future);

      expect(state.status, AdminAccessStatus.authorized);
      expect(state.session?.userId, 'admin-1');
      expect(repository.signOutCalls, 0);
    });

    test('rejects a restored non-Admin session without ending the user session', () async {
      final repository = _AccessRepository(session: AdminSession.anonymous);
      final container = _container(repository);
      addTearDown(container.dispose);

      final state = await container.read(adminAccessControllerProvider.future);

      expect(state.status, AdminAccessStatus.unauthorized);
      expect(repository.signOutCalls, 0);
    });

    test('rejects a revoked Admin role without ending the user session', () async {
      final repository = _AccessRepository(
        fetchFailure: const AdminAccessRevokedException(),
      );
      final container = _container(repository);
      addTearDown(container.dispose);

      final state = await container.read(adminAccessControllerProvider.future);

      expect(state.status, AdminAccessStatus.unauthorized);
      expect(repository.signOutCalls, 0);
    });

    test('does not call the Admin session RPC when auth is expired', () async {
      final repository = _AccessRepository(hasValidSession: false);
      final container = _container(repository);
      addTearDown(container.dispose);

      final state = await container.read(adminAccessControllerProvider.future);

      expect(state.status, AdminAccessStatus.unauthorized);
      expect(repository.fetchSessionCalls, 0);
    });
  });
}

ProviderContainer _container(_AccessRepository repository) {
  return ProviderContainer(
    overrides: [
      adminBackendAvailabilityProvider.overrideWithValue(
        AuthBackendAvailability.ready,
      ),
      adminRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

class _AccessRepository implements AdminRepository {
  final AdminSession session;
  final Object? fetchFailure;
  final bool _hasValidSession;
  int fetchSessionCalls = 0;
  int signOutCalls = 0;

  _AccessRepository({
    this.session = AdminSession.anonymous,
    this.fetchFailure,
    bool hasValidSession = true,
  }) : _hasValidSession = hasValidSession;

  @override
  Stream<void> watchAuthChanges() => const Stream<void>.empty();

  @override
  bool get hasValidSession => _hasValidSession;

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
  Future<AdminSession> fetchSession() async {
    fetchSessionCalls++;
    if (fetchFailure != null) throw fetchFailure!;
    return session;
  }

  @override
  Future<List<AdminDashboardMetric>> fetchDashboardSummary({
    required DateTime from,
    required DateTime to,
    required String scope,
    required String timeZone,
  }) async => const [];

  @override
  Future<List<AdminWorkItem>> fetchSectionItems({
    required AdminPanelSection section,
    required String query,
  }) async => const [];

  @override
  Future<List<AdminAuditEvent>> fetchAuditEvents({
    required String query,
  }) async => const [];

  @override
  Future<AdminMutationResult> runMutation(
    AdminMutationCommand command,
  ) async {
    return const AdminMutationResult(success: true, message: 'ok');
  }
}
