import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app/app_surface_controller.dart';

void main() {
  group('resolveAppSurface', () {
    test('keeps guests and normal users on the user interface', () {
      expect(
        resolveAppSurface(
          isSignedIn: false,
          isAuthorizedAdmin: false,
          canUseUserApp: true,
          requestedSurface: AppSurface.admin,
        ),
        AppSurface.user,
      );
      expect(
        resolveAppSurface(
          isSignedIn: true,
          isAuthorizedAdmin: false,
          canUseUserApp: true,
          requestedSurface: AppSurface.admin,
        ),
        AppSurface.user,
      );
    });

    test('opens every authorized Admin in Admin mode by default', () {
      expect(
        resolveAppSurface(
          isSignedIn: true,
          isAuthorizedAdmin: true,
          canUseUserApp: false,
          requestedSurface: AppSurface.automatic,
        ),
        AppSurface.admin,
      );
      expect(
        resolveAppSurface(
          isSignedIn: true,
          isAuthorizedAdmin: true,
          canUseUserApp: true,
          requestedSurface: AppSurface.automatic,
        ),
        AppSurface.admin,
      );
    });

    test(
      'allows the User surface only after an eligible Admin requests it',
      () {
        expect(
          resolveAppSurface(
            isSignedIn: true,
            isAuthorizedAdmin: true,
            canUseUserApp: false,
            requestedSurface: AppSurface.user,
          ),
          AppSurface.admin,
        );
        expect(
          resolveAppSurface(
            isSignedIn: true,
            isAuthorizedAdmin: true,
            canUseUserApp: true,
            requestedSurface: AppSurface.user,
          ),
          AppSurface.user,
        );
        expect(
          resolveAppSurface(
            isSignedIn: true,
            isAuthorizedAdmin: true,
            canUseUserApp: true,
            requestedSurface: AppSurface.admin,
          ),
          AppSurface.admin,
        );
      },
    );
  });

  test('surface controller starts and resets to automatic selection', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(appSurfaceControllerProvider), AppSurface.automatic);

    container.read(appSurfaceControllerProvider.notifier).showUser();
    expect(container.read(appSurfaceControllerProvider), AppSurface.user);

    container.read(appSurfaceControllerProvider.notifier).reset();
    expect(container.read(appSurfaceControllerProvider), AppSurface.automatic);
  });
}
