import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/Nabi_provider.dart';

/// [NavigatorObserver] tự động cập nhật [NabiContextProvider] khi route thay đổi.
///
/// Đăng ký vào GoRouter:
/// ```dart
/// final v1Router = GoRouter(
///   observers: [NabiRouteObserver(container)],
///   ...
/// );
/// ```
class NabiRouteObserver extends NavigatorObserver {
  final WidgetRef? _ref;
  final ProviderContainer? _container;

  /// Dùng khi có [WidgetRef] (widget context).
  NabiRouteObserver.fromRef(WidgetRef ref) : _ref = ref, _container = null;

  /// Dùng khi chỉ có [ProviderContainer] (root/router level).
  NabiRouteObserver.fromContainer(ProviderContainer container)
    : _ref = null,
      _container = container;

  void _updateRoute(String? routeName) {
    if (routeName == null) return;
    try {
      if (_ref != null) {
        _ref.read(NabiContextProvider.notifier).setRoute(routeName);
      } else {
        _container?.read(NabiContextProvider.notifier).setRoute(routeName);
      }
    } catch (_) {
      // Observer có thể bị gọi trước provider được khởi tạo – bỏ qua
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateRoute(route.settings.name ?? route.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _updateRoute(previousRoute?.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateRoute(newRoute?.settings.name);
  }
}
