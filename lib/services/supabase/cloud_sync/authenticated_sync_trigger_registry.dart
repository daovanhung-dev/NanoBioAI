import 'package:nano_app/app_versions/v2/features/cloud_sync/domain/entities/cloud_sync_result.dart';

/// Bridges app lifecycle/connectivity events into the same authenticated sync
/// coordinator used by AuthController. When UI providers are not ready yet,
/// callers may use their local outbox fallback.
class AuthenticatedSyncTriggerRegistry {
  AuthenticatedSyncTriggerRegistry._();

  static Future<void> Function(AuthSyncReason reason)? _handler;

  static void register(Future<void> Function(AuthSyncReason reason) handler) {
    _handler = handler;
  }

  static void unregister(Future<void> Function(AuthSyncReason reason) handler) {
    if (identical(_handler, handler)) _handler = null;
  }

  static Future<bool> request(AuthSyncReason reason) async {
    final handler = _handler;
    if (handler == null) return false;
    await handler(reason);
    return true;
  }
}
