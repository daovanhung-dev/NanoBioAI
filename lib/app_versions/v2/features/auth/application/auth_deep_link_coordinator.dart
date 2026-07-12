import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';

/// Single owner for both cold-start and warm auth callbacks.
class AuthDeepLinkCoordinator {
  static const _tag = 'AUTH_DEEP_LINK';

  final AppLinks appLinks;
  StreamSubscription<Uri>? _subscription;
  String? _lastHandledUri;

  AuthDeepLinkCoordinator({AppLinks? appLinks})
    : appLinks = appLinks ?? AppLinks();

  Future<void> start(GoRouter router) async {
    await stop();

    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) _handle(router, initial);
    } catch (error, stackTrace) {
      AppLogger.error(_tag, 'Cold auth link read failed', error, stackTrace);
    }

    _subscription = appLinks.uriLinkStream.listen(
      (uri) => _handle(router, uri),
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error(_tag, 'Warm auth link read failed', error, stackTrace);
      },
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _handle(GoRouter router, Uri uri) {
    if (!_isAuthCallback(uri)) return;

    final value = uri.toString();
    if (_lastHandledUri == value) return;
    _lastHandledUri = value;

    router.go(
      '${V2RoutePaths.authCallback}?uri=${Uri.encodeComponent(value)}',
    );
  }

  bool _isAuthCallback(Uri uri) {
    return uri.scheme.toLowerCase() == 'nanobio' &&
        uri.host.toLowerCase() == 'auth' &&
        uri.path == '/callback';
  }
}
