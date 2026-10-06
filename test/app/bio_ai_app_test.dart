import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app/android_runtime_permission_coordinator.dart';
import 'package:nano_app/app/bio_ai_app.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_access_state.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/controllers/admin_access_controller.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_route_state.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/app_versions/v2/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nano_app/core/config/auth_backend_availability.dart';

void main() {
  testWidgets(
    'does not mount the user app while the authenticated identity is unresolved',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            androidRuntimePermissionCoordinatorProvider.overrideWithValue(
              AndroidRuntimePermissionCoordinator(
                gateway: const _GrantedAndroidRuntimePermissionGateway(),
                isAndroid: false,
              ),
            ),
            authBackendAvailabilityProvider.overrideWithValue(
              AuthBackendAvailability.ready,
            ),
            v2AuthChangesProvider.overrideWithValue(
              const AsyncLoading<String?>(),
            ),
          ],
          child: const BioAIApp(),
        ),
      );

      expect(
        find.byKey(const ValueKey('auth-identity-resolving')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('user-app')), findsNothing);
    },
  );

  testWidgets(
    'authorized dual-role Admin opens the Admin app without mounting user onboarding',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            androidRuntimePermissionCoordinatorProvider.overrideWithValue(
              AndroidRuntimePermissionCoordinator(
                gateway: const _GrantedAndroidRuntimePermissionGateway(),
                isAndroid: false,
              ),
            ),
            authBackendAvailabilityProvider.overrideWithValue(
              AuthBackendAvailability.ready,
            ),
            v2AuthControllerProvider.overrideWith(
              _ResolvedAdminAuthController.new,
            ),
            adminAccessControllerProvider.overrideWith(
              _AuthorizedAdminAccessController.new,
            ),
          ],
          child: const BioAIApp(),
        ),
      );
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump();
      }

      expect(find.byKey(const ValueKey('admin-app')), findsOneWidget);
      expect(find.byKey(const ValueKey('user-app')), findsNothing);
    },
  );

  testWidgets('rechecks runtime permissions when the app resumes', (
    tester,
  ) async {
    final gateway = _CountingGrantedAndroidRuntimePermissionGateway();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          androidRuntimePermissionCoordinatorProvider.overrideWithValue(
            AndroidRuntimePermissionCoordinator(
              gateway: gateway,
              isAndroid: true,
            ),
          ),
          authBackendAvailabilityProvider.overrideWithValue(
            AuthBackendAvailability.ready,
          ),
          v2AuthChangesProvider.overrideWithValue(
            const AsyncLoading<String?>(),
          ),
        ],
        child: const BioAIApp(),
      ),
    );
    for (var frame = 0; frame < 3; frame++) {
      await tester.pump();
    }
    expect(
      gateway.statusChecks,
      AndroidRuntimePermissionCoordinator.requestOrder,
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    for (var frame = 0; frame < 3; frame++) {
      await tester.pump();
    }

    expect(gateway.statusChecks, [
      ...AndroidRuntimePermissionCoordinator.requestOrder,
      ...AndroidRuntimePermissionCoordinator.requestOrder,
    ]);
  });

  testWidgets('shows settings guidance and can be dismissed without blocking', (
    tester,
  ) async {
    final gateway = _FakeAndroidRuntimePermissionGateway(
      initialStatus: AndroidRuntimePermissionStatus.granted,
      statusOverrides: const {
        AndroidRuntimePermission.callPhone:
            AndroidRuntimePermissionStatus.permanentlyDenied,
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          androidRuntimePermissionCoordinatorProvider.overrideWithValue(
            AndroidRuntimePermissionCoordinator(
              gateway: gateway,
              isAndroid: true,
            ),
          ),
          authBackendAvailabilityProvider.overrideWithValue(
            AuthBackendAvailability.ready,
          ),
          v2AuthControllerProvider.overrideWith(
            _ResolvedAdminAuthController.new,
          ),
          adminAccessControllerProvider.overrideWith(
            _AuthorizedAdminAccessController.new,
          ),
        ],
        child: const BioAIApp(),
      ),
    );
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump();
    }

    expect(find.text('Một số quyền đang tắt'), findsOneWidget);
    expect(find.text('Mở Cài đặt'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-app')), findsOneWidget);

    await tester.tap(find.text('Để sau'));
    await tester.pump();

    expect(find.text('Một số quyền đang tắt'), findsNothing);
    expect(find.byKey(const ValueKey('admin-app')), findsOneWidget);
  });
}

class _AuthorizedAdminAccessController extends AdminAccessController {
  @override
  Future<AdminAccessState> build() async {
    return const AdminAccessState.authorized(
      AdminSession(
        userId: 'admin-1',
        roles: [AdminRoleCode.superAdmin],
        permissions: {AdminPermissions.wildcard},
        active: true,
        canUseUserApp: true,
      ),
    );
  }
}

class _ResolvedAdminAuthController extends AuthController {
  @override
  Future<AuthRouteState> build() async =>
      const AuthRouteState.authenticatedReady(userId: 'admin-1');
}

class _GrantedAndroidRuntimePermissionGateway
    implements AndroidRuntimePermissionGateway {
  const _GrantedAndroidRuntimePermissionGateway();

  @override
  Future<AndroidRuntimePermissionStatus> status(
    AndroidRuntimePermission permission,
  ) async => AndroidRuntimePermissionStatus.granted;

  @override
  Future<AndroidRuntimePermissionStatus> request(
    AndroidRuntimePermission permission,
  ) async => AndroidRuntimePermissionStatus.granted;

  @override
  Future<bool> openAppSettings() async => true;
}

class _FakeAndroidRuntimePermissionGateway
    implements AndroidRuntimePermissionGateway {
  _FakeAndroidRuntimePermissionGateway({
    required this.initialStatus,
    this.statusOverrides = const {},
  });

  final AndroidRuntimePermissionStatus initialStatus;
  final Map<AndroidRuntimePermission, AndroidRuntimePermissionStatus>
  statusOverrides;

  @override
  Future<AndroidRuntimePermissionStatus> status(
    AndroidRuntimePermission permission,
  ) async => statusOverrides[permission] ?? initialStatus;

  @override
  Future<AndroidRuntimePermissionStatus> request(
    AndroidRuntimePermission permission,
  ) async => AndroidRuntimePermissionStatus.granted;

  @override
  Future<bool> openAppSettings() async => true;
}

class _CountingGrantedAndroidRuntimePermissionGateway
    implements AndroidRuntimePermissionGateway {
  final statusChecks = <AndroidRuntimePermission>[];

  @override
  Future<AndroidRuntimePermissionStatus> status(
    AndroidRuntimePermission permission,
  ) async {
    statusChecks.add(permission);
    return AndroidRuntimePermissionStatus.granted;
  }

  @override
  Future<AndroidRuntimePermissionStatus> request(
    AndroidRuntimePermission permission,
  ) async => AndroidRuntimePermissionStatus.granted;

  @override
  Future<bool> openAppSettings() async => true;
}
