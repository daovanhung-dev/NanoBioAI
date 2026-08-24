import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';

typedef NotificationNavigator = void Function(Uri uri);

class NotificationNavigationCoordinator {
  NotificationNavigationCoordinator._();

  static NotificationNavigator? _navigator;
  static Uri? _pendingUri;

  static void register(NotificationNavigator navigator) {
    _navigator = navigator;
    final pending = _pendingUri;
    if (pending == null) return;
    _pendingUri = null;
    navigator(pending);
  }

  static void unregister(NotificationNavigator navigator) {
    if (identical(_navigator, navigator)) _navigator = null;
  }

  static void openScheduleItem(String sourceId) {
    final normalized = sourceId.trim();
    _open(
      Uri(
        path: V1RoutePaths.lifestyleSchedule,
        queryParameters: normalized.isEmpty ? null : {'item': normalized},
      ),
    );
  }

  static void openSleepSafety() {
    _open(Uri(
      path: V1RoutePaths.sleepTracking,
      queryParameters: const {'source': 'scheduled_reminder'},
    ));
  }

  static void _open(Uri uri) {
    final navigator = _navigator;
    if (navigator == null) {
      _pendingUri = uri;
      return;
    }
    navigator(uri);
  }

  static void resetForTest() {
    _navigator = null;
    _pendingUri = null;
  }
}
