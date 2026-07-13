import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppSurface { user, admin }

AppSurface resolveAppSurface({
  required bool isSignedIn,
  required bool isAuthorizedAdmin,
  required bool canUseUserApp,
  required AppSurface requestedSurface,
}) {
  if (!isSignedIn || !isAuthorizedAdmin) return AppSurface.user;
  if (!canUseUserApp) return AppSurface.admin;
  return requestedSurface;
}

final appSurfaceControllerProvider =
    NotifierProvider<AppSurfaceController, AppSurface>(
      AppSurfaceController.new,
    );

class AppSurfaceController extends Notifier<AppSurface> {
  @override
  AppSurface build() => AppSurface.user;

  void showUser() => state = AppSurface.user;

  void showAdmin() => state = AppSurface.admin;

  void reset() => state = AppSurface.user;
}
