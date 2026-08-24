import 'package:flutter/widgets.dart';

import 'app_log_category.dart';
import 'app_log_level.dart';
import 'app_logger.dart';

class AppRouteLogObserver extends NavigatorObserver {
  AppRouteLogObserver({required this.scope});

  final String scope;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('PUSH', route, previousRoute);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('POP', route, previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _log('REPLACE', newRoute, oldRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('REMOVE', route, previousRoute);
    super.didRemove(route, previousRoute);
  }

  void _log(
    String action,
    Route<dynamic>? route,
    Route<dynamic>? previousRoute,
  ) {
    AppLogger.event(
      level: AppLogLevel.debug,
      category: AppLogCategory.navigation,
      scope: scope,
      operation: action,
      message: 'navigation breadcrumb',
      metadata: {
        'fromRoute': _routeName(previousRoute),
        'toRoute': _routeName(route),
      },
    );
  }

  static void redirect({
    required String scope,
    required String from,
    required String to,
    required String reason,
  }) {
    AppLogger.event(
      level: AppLogLevel.warn,
      category: AppLogCategory.navigation,
      scope: scope,
      operation: 'REDIRECT',
      message: 'route redirected',
      metadata: {
        'fromRoute': from,
        'toRoute': to,
        'reason': reason,
      },
    );
  }

  static String _routeName(Route<dynamic>? route) {
    if (route == null) return '<none>';
    return route.settings.name ?? route.runtimeType.toString();
  }
}
