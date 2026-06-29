import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

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
        if (error != null) 'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
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
        if (error != null) 'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
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
        if (error != null) 'error': error.toString(),
      },
    );
  }

  static void _log(String level, String message, {Map<String, Object?>? data}) {
    final timestamp = DateTime.now().toIso8601String();
    final dataStr = data != null && data.isNotEmpty
        ? '\n  Data: ${_formatData(data)}'
        : '';

    final logMessage = '[$_tag] [$level] $message$dataStr';

    // Print to console in debug mode
    if (kDebugMode) {
      // ignore: avoid_print
      print('[$timestamp] $logMessage');
    }

    // Send to DevTools timeline
    developer.log(
      message,
      time: DateTime.now(),
      name: '$_tag.$level',
      level: _levelToInt(level),
      error: data?['error'],
      stackTrace: data?['stackTrace'] is StackTrace
          ? data!['stackTrace'] as StackTrace
          : null,
    );
  }

  static int _levelToInt(String level) {
    return switch (level) {
      'ERROR' || 'RPC-ERROR' || 'MUTATION-ERROR' => 1000, // Severe
      'WARN' => 900, // Warning
      _ => 800, // Info
    };
  }

  static String _formatData(Map<String, Object?> data) {
    return data.entries
        .map((e) => '${e.key}=${_formatValue(e.value)}')
        .join(', ');
  }

  static String _formatValue(Object? value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    if (value is Map) return '{${value.length} entries}';
    if (value is List) return '[${value.length} items]';
    return value.toString();
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

  /// Export logs for bug report (placeholder for future implementation)
  static Future<String> exportLogs() async {
    // TODO: Implement log export to file
    return 'Logs exported at ${DateTime.now()}';
  }
}
