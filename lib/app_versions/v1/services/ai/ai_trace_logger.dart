import 'dart:convert';

import 'package:nano_app/core/utils/logger/app_logger.dart';

class AITraceLogger {
  static const aiGen = 'AI_GEN';
  static const localGen = 'LOCAL_GEN';

  static const _allowedMetadataKeys = {
    'chunkCount',
    'chunkDays',
    'chunkStartDay',
    'codeItemCount',
    'cooldownMs',
    'cooldownSkips',
    'days',
    'delayMs',
    'distinctCodeCount',
    'durationMs',
    'errorType',
    'exerciseCount',
    'itemCount',
    'lastErrorType',
    'mealCount',
    'messageLength',
    'model',
    'modelAttempt',
    'models',
    'nextTotalAttempt',
    'perModelTimeoutMs',
    'promptLength',
    'responseLength',
    'scheduleTaskCount',
    'source',
    'reason',
    'textLength',
    'totalAttempt',
    'totalAttempts',
    'transient',
    'retryable',
    'streaming',
  };

  static int _sequence = 0;

  const AITraceLogger._();

  static String nextTraceId(String scope) {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final sequence = (++_sequence).toString().padLeft(4, '0');
    return '$scope-$timestamp-$sequence';
  }

  static void start(
    String tag,
    String traceId,
    String method, {
    Map<String, Object?> data = const {},
    StackTrace? location,
  }) {
    info(
      tag,
      traceId,
      method,
      'START',
      'Bắt đầu luồng xử lý',
      data: data,
      location: location,
    );
  }

  static void success(
    String tag,
    String traceId,
    String method,
    String step,
    String message, {
    Map<String, Object?> data = const {},
    StackTrace? location,
  }) {
    AppLogger.success(tag, _line(traceId, method, step, message));
    if (data.isNotEmpty) {
      _metadata(tag, traceId, method, '$step.data', data);
    }
  }

  static void info(
    String tag,
    String traceId,
    String method,
    String step,
    String message, {
    Map<String, Object?> data = const {},
    StackTrace? location,
  }) {
    AppLogger.info(tag, _line(traceId, method, step, message));
    if (data.isNotEmpty) {
      _metadata(tag, traceId, method, '$step.data', data);
    }
  }

  static void warning(
    String tag,
    String traceId,
    String method,
    String step,
    String message, {
    Map<String, Object?> data = const {},
    StackTrace? location,
  }) {
    AppLogger.warning(tag, _line(traceId, method, step, message));
    if (data.isNotEmpty) {
      _metadata(tag, traceId, method, '$step.data', data);
    }
  }

  static void error(
    String tag,
    String traceId,
    String method,
    String step,
    String message,
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?> data = const {},
    StackTrace? location,
  }) {
    AppLogger.error(tag, _line(traceId, method, step, message));
    _metadata(tag, traceId, method, '$step.data', {
      ...data,
      'errorType': error.runtimeType.toString(),
    });
  }

  static void _metadata(
    String tag,
    String traceId,
    String method,
    String step,
    Map<String, Object?> data,
  ) {
    final sanitized = <String, Object?>{};
    for (final entry in data.entries) {
      if (!_isAllowedMetadataKey(entry.key)) continue;
      final value = _safeMetadataValue(entry.key, entry.value);
      if (value != null) {
        sanitized[entry.key] = value;
      }
    }
    if (sanitized.isEmpty) return;

    AppLogger.info(tag, _line(traceId, method, step, jsonEncode(sanitized)));
  }

  static String _line(
    String traceId,
    String method,
    String step,
    String message,
  ) {
    return 'traceId=$traceId method=$method step=$step $message';
  }

  static bool _isAllowedMetadataKey(String key) {
    return _allowedMetadataKeys.contains(key);
  }

  static Object? _safeMetadataValue(String key, Object? value) {
    if (value is num || value is bool) {
      return value;
    }
    if (value is String) {
      return value;
    }
    if (key == 'models' && value is Iterable<String>) {
      return value.toList(growable: false);
    }
    return null;
  }
}
