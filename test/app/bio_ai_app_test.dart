import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app/bio_ai_app.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_access_state.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/controllers/admin_access_controller.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/core/config/auth_backend_availability.dart';

void main() {
  testWidgets(
    'does not mount the user app while the authenticated identity is unresolved',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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
            authBackendAvailabilityProvider.overrideWithValue(
              AuthBackendAvailability.ready,
            ),
            v2AuthChangesProvider.overrideWithValue(
              const AsyncData<String?>('admin-1'),
            ),
            currentAuthUserIdProvider.overrideWithValue('admin-1'),
            adminAccessControllerProvider.overrideWith(
              _AuthorizedAdminAccessController.new,
            ),
          ],
          child: const BioAIApp(),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('admin-app')), findsOneWidget);
      expect(find.byKey(const ValueKey('user-app')), findsNothing);
    },
  );
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
