import 'package:nano_app/core/utils/logger/app_log_category.dart';
import 'package:nano_app/core/utils/logger/app_log_level.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';

class AITraceLogger {
  static const aiGen = 'AI_GEN';
  static const localGen = 'LOCAL_GEN';

  static const _allowedMetadataKeys = {
    'chunkCount',
    'chunkDays',
    'chunkStartDay',
    'codeItemCount',
    'contentsCount',
    'cooldownMs',
    'cooldownSkips',
    'days',
    'delayMs',
    'distinctCodeCount',
    'durationMs',
    'errorCode',
    'errorType',
    'exerciseCount',
    'functionName',
    'hasSystemInstruction',
    'itemCount',
    'lastErrorType',
    'maxOutputTokens',
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
    'status',
    'statusCode',
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
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
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
    _write(
      level: AppLogLevel.info,
      tag: tag,
      traceId: traceId,
      method: method,
      step: step,
      message: message,
      data: data,
    );
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
    _write(
      level: AppLogLevel.debug,
      tag: tag,
      traceId: traceId,
      method: method,
      step: step,
      message: message,
      data: data,
    );
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
    _write(
      level: AppLogLevel.warn,
      tag: tag,
      traceId: traceId,
      method: method,
      step: step,
      message: message,
      data: data,
    );
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
    AppLogger.captureError(
      category: AppLogCategory.ai,
      scope: tag,
      operation: '$method.$step',
      message: message,
      error: error,
      stackTrace: stackTrace,
      correlationId: traceId,
      metadata: _sanitizeMetadata({
        ...data,
        'errorType': error.runtimeType.toString(),
      }),
    );
  }

  static void _write({
    required AppLogLevel level,
    required String tag,
    required String traceId,
    required String method,
    required String step,
    required String message,
    required Map<String, Object?> data,
  }) {
    AppLogger.event(
      level: level,
      category: AppLogCategory.ai,
      scope: tag,
      operation: '$method.$step',
      message: message,
      correlationId: traceId,
      metadata: _sanitizeMetadata(data),
    );
  }

  static Map<String, Object?> _sanitizeMetadata(Map<String, Object?> data) {
    final sanitized = <String, Object?>{};
    for (final entry in data.entries) {
      if (!_allowedMetadataKeys.contains(entry.key)) continue;
      final value = _safeMetadataValue(entry.key, entry.value);
      if (value != null) sanitized[entry.key] = value;
    }
    return sanitized;
  }

  static Object? _safeMetadataValue(String key, Object? value) {
    if (value is num || value is bool || value is String) return value;
    if (key == 'models' && value is Iterable<String>) {
      return value.toList(growable: false);
    }
    return null;
  }
}
