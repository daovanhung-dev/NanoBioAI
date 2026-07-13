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

    test('forces an Admin-only account into the Admin interface', () {
      expect(
        resolveAppSurface(
          isSignedIn: true,
          isAuthorizedAdmin: true,
          canUseUserApp: false,
          requestedSurface: AppSurface.user,
        ),
        AppSurface.admin,
      );
    });

    test('lets a dual-role account switch between both interfaces', () {
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
    });
  });
}
