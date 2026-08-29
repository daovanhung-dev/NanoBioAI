import 'package:nano_app/core/utils/logger/app_log_category.dart';
import 'package:nano_app/core/utils/logger/app_log_level.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';

/// Admin-specific logger for debugging and troubleshooting.
///
/// Usage:
/// ```dart
/// AdminLogger.info('User logged in', data: {'email': email});
/// AdminLogger.error('RPC failed', error: e, stackTrace: st);
/// AdminLogger.rpc('get_my_admin_session', params: {...}, result: {...});
/// ```
///
/// Logs are:
/// - Printed to console in debug mode
/// - Sent to Flutter DevTools timeline
/// - Can be exported for bug reports
abstract class AdminLogger {
  static const _tag = 'NanoBio.Admin';

  /// Log info-level message
  static void info(String message, {Map<String, Object?>? data}) {
    _log('INFO', message, data: data);
  }

  /// Log warning-level message
  static void warning(String message, {Map<String, Object?>? data}) {
    _log('WARN', message, data: data);
  }

  /// Log error-level message with optional exception
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? data,
  }) {
    _log(
      'ERROR',
      message,
      data: {
        if (data != null) ...data,
        if (error != null) 'errorType': error.runtimeType.toString(),
        if (stackTrace != null) 'stackTracePresent': true,
      },
    );
  }

  /// Log RPC call with params and result/error
  static void rpc(
    String rpcName, {
    Map<String, Object?>? params,
    Object? result,
    Object? error,
    StackTrace? stackTrace,
    Duration? duration,
  }) {
    _log(
      error != null ? 'RPC-ERROR' : 'RPC',
      rpcName,
      data: {
        if (params != null) 'params': _sanitize(params),
        if (result != null) 'result': _sanitize(result),
        if (error != null) 'errorType': error.runtimeType.toString(),
        if (stackTrace != null) 'stackTracePresent': true,
        if (duration != null) 'duration_ms': duration.inMilliseconds,
      },
    );
  }

  /// Log auth event
  static void auth(
    String event, {
    String? email,
    String? userId,
    Map<String, Object?>? data,
  }) {
    _log(
      'AUTH',
      event,
      data: {
        if (email != null) 'email': _maskEmail(email),
        if (userId != null) 'userId': userId,
        if (data != null) ...data,
      },
    );
  }

  /// Log session check
  static void session({
    required bool hasAuth,
    required bool isAdmin,
    List<String>? roles,
    List<String>? permissions,
  }) {
    _log(
      'SESSION',
      'Admin session checked',
      data: {
        'hasAuth': hasAuth,
        'isAdmin': isAdmin,
        if (roles != null) 'roles': roles,
        if (permissions != null) 'permissions': permissions,
      },
    );
  }

  /// Log navigation event
  static void navigation(String route, {Map<String, Object?>? data}) {
    _log('NAV', route, data: data);
  }

  /// Log mutation command
  static void mutation(
    String action, {
    required String section,
    required String targetId,
    required String reason,
    Map<String, Object?>? payload,
    Object? result,
    Object? error,
  }) {
    _log(
      error != null ? 'MUTATION-ERROR' : 'MUTATION',
      action,
      data: {
        'section': section,
        'targetId': targetId,
        'reason': reason,
        if (payload != null) 'payload': _sanitize(payload),
        if (result != null) 'result': _sanitize(result),
        if (error != null) 'errorType': error.runtimeType.toString(),
      },
    );
  }

  static void _log(String level, String message, {Map<String, Object?>? data}) {
    final sanitized = data == null
        ? const <String, Object?>{}
        : Map<String, Object?>.from(_sanitize(data) as Map);
    AppLogger.event(
      level: switch (level) {
        'ERROR' || 'RPC-ERROR' || 'MUTATION-ERROR' => AppLogLevel.error,
        'WARN' => AppLogLevel.warn,
        _ => AppLogLevel.info,
      },
      category: AppLogCategory.app,
      scope: _tag,
      operation: level,
      message: message,
      metadata: sanitized,
    );
  }

  /// Sanitize sensitive data before logging
  static Object? _sanitize(Object? value) {
    if (value is Map) {
      return Map.fromEntries(
        value.entries.map((e) {
          final key = e.key.toString().toLowerCase();
          // Mask sensitive fields
          if (key.contains('password') ||
              key.contains('token') ||
              key.contains('secret') ||
              key.contains('key')) {
            return MapEntry(e.key, '***');
          }
          if (key.contains('email')) {
            return MapEntry(e.key, _maskEmail(e.value.toString()));
          }
          return MapEntry(e.key, _sanitize(e.value));
        }),
      );
    }
    if (value is List) {
      return value.map(_sanitize).toList();
    }
    return value;
  }

  static String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***';
    final username = parts[0];
    final domain = parts[1];
    if (username.length <= 2) return '***@$domain';
    return '${username[0]}***${username[username.length - 1]}@$domain';
  }

  /// Returns a safe export marker for the bug-report workflow.
  ///
  /// Persistent file creation belongs to the platform sharing layer; keeping
  /// this logger free of file-system access avoids leaking unsanitized data.
  static Future<String> exportLogs() async {
    final exportedAt = DateTime.now().toIso8601String();
    return 'NanoBio Admin log export requested at $exportedAt';
  }
}
