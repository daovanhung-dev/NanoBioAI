import 'package:flutter/foundation.dart';

import 'app_log_category.dart';
import 'app_log_event.dart';
import 'app_log_level.dart';
import 'log_redactor.dart';
import 'terminal_log_sink.dart';

class AppLogger {
  AppLogger._();

  static int _sequence = 0;

  static AppLogLevel get _minimumLevel {
    if (kDebugMode) return AppLogLevel.trace;
    if (kProfileMode) return AppLogLevel.info;
    return AppLogLevel.warn;
  }

  static String newCorrelationId([String prefix = 'req']) {
    final sequence = (++_sequence).toRadixString(36).padLeft(4, '0');
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return '$prefix-$micros-$sequence';
  }

  static void event({
    required AppLogLevel level,
    required AppLogCategory category,
    required String scope,
    required String operation,
    required String message,
    String? correlationId,
    Duration? duration,
    Map<String, Object?> metadata = const <String, Object?>{},
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minimumLevel.index) return;

    final event = AppLogEvent(
      timestamp: DateTime.now(),
      sequence: ++_sequence,
      level: level,
      category: category,
      scope: LogRedactor.text(scope, maxLength: 80),
      operation: LogRedactor.text(operation, maxLength: 80),
      message: LogRedactor.text(message),
      correlationId: correlationId == null
          ? null
          : LogRedactor.text(correlationId, maxLength: 100),
      duration: duration,
      metadata: LogRedactor.metadata(metadata),
      errorType: error?.runtimeType.toString(),
      stackTrace: stackTrace == null ? null : LogRedactor.stack(stackTrace),
    );
    TerminalLogSink.write(_format(event));
  }

  static void captureError({
    required AppLogCategory category,
    required String scope,
    required String operation,
    required String message,
    required Object error,
    required StackTrace stackTrace,
    AppLogLevel level = AppLogLevel.error,
    String? correlationId,
    Duration? duration,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    event(
      level: level,
      category: category,
      scope: scope,
      operation: operation,
      message: message,
      correlationId: correlationId,
      duration: duration,
      metadata: metadata,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void performance({
    required String scope,
    required String operation,
    required Duration duration,
    Duration warnThreshold = const Duration(milliseconds: 500),
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    event(
      level: duration >= warnThreshold ? AppLogLevel.warn : AppLogLevel.debug,
      category: AppLogCategory.performance,
      scope: scope,
      operation: operation,
      message: duration >= warnThreshold ? 'slow operation detected' : 'operation timing',
      duration: duration,
      metadata: {
        ...metadata,
        'thresholdMs': warnThreshold.inMilliseconds,
      },
    );
  }

  static bool invariant(
    bool condition, {
    required String code,
    required String scope,
    String message = 'Invariant failed',
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    if (condition) return true;
    event(
      level: AppLogLevel.error,
      category: AppLogCategory.logic,
      scope: scope,
      operation: code,
      message: message,
      metadata: metadata,
    );
    return false;
  }

  static Future<T> guardAsync<T>({
    required AppLogCategory category,
    required String scope,
    required String operation,
    required Future<T> Function() action,
    String? correlationId,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await action();
      stopwatch.stop();
      event(
        level: AppLogLevel.debug,
        category: category,
        scope: scope,
        operation: operation,
        message: 'completed',
        correlationId: correlationId,
        duration: stopwatch.elapsed,
        metadata: metadata,
      );
      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();
      captureError(
        category: category,
        scope: scope,
        operation: operation,
        message: 'failed',
        error: error,
        stackTrace: stackTrace,
        correlationId: correlationId,
        duration: stopwatch.elapsed,
        metadata: metadata,
      );
      rethrow;
    }
  }

  static void legacyPrint(String? message, {String source = 'print'}) {
    final normalized = message?.trim();
    if (normalized == null || normalized.isEmpty) return;
    event(
      level: AppLogLevel.debug,
      category: AppLogCategory.app,
      scope: 'LegacyLogBridge',
      operation: source,
      message: normalized,
    );
  }

  // Backward-compatible facade for existing project call sites.
  static void info(String tag, String message) {
    event(
      level: AppLogLevel.info,
      category: AppLogCategory.app,
      scope: tag,
      operation: 'INFO',
      message: message,
    );
  }

  static void success(String tag, String message) {
    event(
      level: AppLogLevel.info,
      category: AppLogCategory.app,
      scope: tag,
      operation: 'SUCCESS',
      message: message,
      metadata: const {'status': 'success'},
    );
  }

  static void warning(String tag, String message) {
    event(
      level: AppLogLevel.warn,
      category: AppLogCategory.app,
      scope: tag,
      operation: 'WARNING',
      message: message,
    );
  }

  static void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    event(
      level: AppLogLevel.error,
      category: AppLogCategory.app,
      scope: tag,
      operation: 'ERROR',
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void validation(
    String tag,
    String field,
    bool passed, {
    String? reason,
  }) {
    event(
      level: passed ? AppLogLevel.debug : AppLogLevel.warn,
      category: AppLogCategory.logic,
      scope: tag,
      operation: 'VALIDATION',
      message: passed ? 'validation passed' : 'validation failed',
      metadata: {
        'field': field,
        'passed': passed,
        if (reason != null) 'reason': reason,
      },
    );
  }

  static void form(String tag, String field, dynamic value) {
    event(
      level: AppLogLevel.debug,
      category: AppLogCategory.ui,
      scope: tag,
      operation: 'FORM',
      message: 'form value changed',
      metadata: {'field': field, 'valueState': _safeFormValue(value)},
    );
  }

  static void navigation(String tag, String from, String to) {
    event(
      level: AppLogLevel.debug,
      category: AppLogCategory.navigation,
      scope: tag,
      operation: 'NAVIGATE',
      message: 'route transition',
      metadata: {'fromRoute': from, 'toRoute': to},
    );
  }

  static void provider(String tag, String description) {
    event(
      level: AppLogLevel.debug,
      category: AppLogCategory.logic,
      scope: tag,
      operation: 'PROVIDER',
      message: description,
    );
  }

  static void database(String tag, String operation) {
    event(
      level: AppLogLevel.debug,
      category: AppLogCategory.database,
      scope: tag,
      operation: operation,
      message: 'database operation',
    );
  }

  static void supabase(String tag, String operation) {
    event(
      level: AppLogLevel.debug,
      category: AppLogCategory.supabase,
      scope: tag,
      operation: operation,
      message: 'supabase operation',
    );
  }

  static void action(String tag, String action) {
    event(
      level: AppLogLevel.info,
      category: AppLogCategory.app,
      scope: tag,
      operation: 'ACTION',
      message: action,
    );
  }

  static void summary(String tag, String title, Map<String, dynamic> data) {
    event(
      level: AppLogLevel.info,
      category: AppLogCategory.app,
      scope: tag,
      operation: 'SUMMARY',
      message: title,
      metadata: Map<String, Object?>.from(data),
    );
  }

  static void separator([String tag = 'LOG']) {
    event(
      level: AppLogLevel.debug,
      category: AppLogCategory.app,
      scope: tag,
      operation: 'SEPARATOR',
      message: '=' * 60,
    );
  }

  static String _safeFormValue(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return 'empty';
    if (text == 'provided' ||
        text == 'accepted' ||
        text == 'not_accepted' ||
        RegExp(r'^count=\d+$').hasMatch(text)) {
      return text;
    }
    return 'updated';
  }

  static String _format(AppLogEvent event) {
    final timestamp = event.timestamp;
    final time = '${_two(timestamp.hour)}:${_two(timestamp.minute)}:'
        '${_two(timestamp.second)}.${timestamp.millisecond.toString().padLeft(3, '0')}';
    final sequence = event.sequence.toString().padLeft(5, '0');
    final buffer = StringBuffer()
      ..write('[$time][#$sequence][${event.level.label}]')
      ..write('[${event.category.label}]')
      ..write('[${event.scope}][${event.operation}]');
    if (event.correlationId != null) {
      buffer.write('[corr=${event.correlationId}]');
    }
    if (event.duration != null) {
      buffer.write('[${event.duration!.inMilliseconds}ms]');
    }
    buffer.write(' ${event.message}');
    if (event.metadata.isNotEmpty) {
      buffer.write(' ${_formatMetadata(event.metadata)}');
    }
    if (event.errorType != null) {
      buffer.write(' errorType=${event.errorType}');
    }
    if (event.stackTrace != null && event.stackTrace!.trim().isNotEmpty) {
      buffer.write('\nStackTrace:\n${event.stackTrace}');
    }
    return buffer.toString();
  }

  static String _formatMetadata(Map<String, Object?> metadata) {
    return metadata.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
