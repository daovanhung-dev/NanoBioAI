import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/nabi_controller.dart';
import 'nabi_route_mapper.dart';

/// NavigatorObserver để Nabi tự đổi biểu cảm khi người dùng chuyển màn hình.
///
/// Thêm observer này vào GoRouter thay vì gọi setContext thủ công ở từng page.
class NabiRouteObserver extends NavigatorObserver {
  NabiRouteObserver(this._onLocationChanged);

  final void Function(String location) _onLocationChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _notify(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _notify(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) _notify(previousRoute);
  }

  void _notify(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.trim().isEmpty) return;
    _onLocationChanged(name);
  }
}

/// Đặt trong provider tạo GoRouter để observer luôn dùng đúng ProviderContainer.
NabiRouteObserver createNabiRouteObserver(Ref ref) {
  return NabiRouteObserver((location) {
    ref
        .read(nabiControllerProvider.notifier)
        .setContext(NabiRouteMapper.fromLocation(location));
  });
}
