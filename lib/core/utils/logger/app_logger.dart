import 'package:flutter/foundation.dart';

/// AppLogger - Centralized logging system for debugging and monitoring
///
/// Usage:
/// ```dart
/// AppLogger.info('TAG', 'Information message');
/// AppLogger.success('TAG', 'Success message');
/// AppLogger.warning('TAG', 'Warning message');
/// AppLogger.error('TAG', 'Error message', error, stackTrace);
/// ```
class AppLogger {
  AppLogger._();

  static const _enableLogging = true;

  /// Log informational messages
  /// Format: [TAG][INFO] message
  static void info(String tag, String message) {
    if (!_enableLogging) return;
    debugPrint('[$tag][INFO] $message');
  }

  /// Log success messages
  /// Format: [TAG][SUCCESS] message
  static void success(String tag, String message) {
    if (!_enableLogging) return;
    debugPrint('[$tag][SUCCESS] $message');
  }

  /// Log warning messages
  /// Format: [TAG][WARNING] message
  static void warning(String tag, String message) {
    if (!_enableLogging) return;
    debugPrint('[$tag][WARNING] $message');
  }

  /// Log error messages with optional error object and stack trace
  /// Format: [TAG][ERROR] message
  ///         Error: error
  ///         StackTrace: stackTrace
  static void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!_enableLogging) return;

    debugPrint('[$tag][ERROR] $message');

    if (error != null) {
      debugPrint('Error: $error');
    }

    if (stackTrace != null) {
      debugPrint('StackTrace:\n$stackTrace');
    }
  }

  /// Log validation results
  /// Format: [TAG][VALIDATION] field - status
  ///         Reason: reason (if failed)
  static void validation(
    String tag,
    String field,
    bool passed, {
    String? reason,
  }) {
    if (!_enableLogging) return;

    final status = passed ? 'Passed' : 'Failed';
    debugPrint('[$tag][VALIDATION] $field - $status');

    if (!passed && reason != null) {
      debugPrint('Reason: $reason');
    }
  }

  /// Log form data changes
  /// Format: [TAG][FORM] field = value
  static void form(String tag, String field, dynamic value) {
    if (!_enableLogging) return;
    debugPrint('[$tag][FORM] $field = $value');
  }

  /// Log navigation events
  /// Format: [TAG][ROUTER] from → to
  static void navigation(String tag, String from, String to) {
    if (!_enableLogging) return;
    debugPrint('[$tag][ROUTER] Navigate: $from → $to');
  }

  /// Log provider state changes
  /// Format: [TAG][PROVIDER] description
  static void provider(String tag, String description) {
    if (!_enableLogging) return;
    debugPrint('[$tag][PROVIDER] $description');
  }

  /// Log database operations
  /// Format: [TAG][LOCAL_DB] operation
  static void database(String tag, String operation) {
    if (!_enableLogging) return;
    debugPrint('[$tag][LOCAL_DB] $operation');
  }

  /// Log API/Supabase operations
  /// Format: [TAG][SUPABASE] operation
  static void supabase(String tag, String operation) {
    if (!_enableLogging) return;
    debugPrint('[$tag][SUPABASE] $operation');
  }

  /// Log user actions
  /// Format: [TAG] action
  static void action(String tag, String action) {
    if (!_enableLogging) return;
    debugPrint('[$tag] $action');
  }

  /// Log summary/statistics
  /// Format: [TAG][SUMMARY] title
  ///         - item1: value1
  ///         - item2: value2
  static void summary(String tag, String title, Map<String, dynamic> data) {
    if (!_enableLogging) return;

    debugPrint('[$tag][SUMMARY] $title');
    data.forEach((key, value) {
      debugPrint('  - $key: $value');
    });
  }

  /// Log separator line for visual clarity
  static void separator([String tag = 'LOG']) {
    if (!_enableLogging) return;
    debugPrint('[$tag] ${'=' * 60}');
  }
}
