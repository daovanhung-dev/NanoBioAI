import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppSurface { automatic, user, admin }

AppSurface resolveAppSurface({
  required bool isSignedIn,
  required bool isAuthorizedAdmin,
  required bool canUseUserApp,
  required AppSurface requestedSurface,
}) {
  if (!isSignedIn || !isAuthorizedAdmin) return AppSurface.user;
  if (requestedSurface == AppSurface.user && canUseUserApp) {
    return AppSurface.user;
  }
  return AppSurface.admin;
}

final appSurfaceControllerProvider =
    NotifierProvider<AppSurfaceController, AppSurface>(
      AppSurfaceController.new,
    );

class AppSurfaceController extends Notifier<AppSurface> {
  @override
  AppSurface build() => AppSurface.automatic;

  void showUser() => state = AppSurface.user;

  void showAdmin() => state = AppSurface.admin;

  void reset() => state = AppSurface.automatic;
}
