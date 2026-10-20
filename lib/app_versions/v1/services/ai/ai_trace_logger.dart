import 'dart:io';

import 'package:flutter/foundation.dart';

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
    'candidateCount',
    'candidateGroups',
    'catalogMealCount',
    'contentsCount',
    'cooldownMs',
    'cooldownSkips',
    'contextSize',
    'days',
    'day',
    'delayMs',
    'distinctCodeCount',
    'durationMs',
    'availableTokens',
    'errorCode',
    'errorType',
    'exerciseCount',
    'firstTokenMs',
    'filteredMealCount',
    'functionName',
    'hasSystemInstruction',
    'inferenceDurationMs',
    'inputTokens',
    'itemCount',
    'lastErrorType',
    'maxOutputTokens',
    'mealCount',
    'messageLength',
    'model',
    'modelAttempt',
    'models',
    'nextTotalAttempt',
    'outputReserveTokens',
    'outputTokens',
    'positionMatchCount',
    'reassignedCount',
    'perModelTimeoutMs',
    'promptLength',
    'queueWaitMs',
    'responseLength',
    'scheduleTaskCount',
    'source',
    'reason',
    'status',
    'statusCode',
    'textLength',
    'tokenizationDurationMs',
    'totalAttempt',
    'totalAttempts',
    'transient',
    'retryable',
    'streaming',
  };

  static int _sequence = 0;
  static Future<void> _debugWriteChain = Future<void>.value();

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
    final safeMetadata = _sanitizeMetadata({
      ...data,
      'errorType': error.runtimeType.toString(),
    });
    AppLogger.event(
      level: AppLogLevel.error,
      category: AppLogCategory.ai,
      scope: tag,
      operation: '$method.$step',
      message: message,
      error: error,
      correlationId: traceId,
      metadata: safeMetadata,
    );
    _debugTrace(method, step, safeMetadata);
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
    final safeMetadata = _sanitizeMetadata(data);
    AppLogger.event(
      level: level,
      category: AppLogCategory.ai,
      scope: tag,
      operation: '$method.$step',
      message: message,
      correlationId: traceId,
      metadata: safeMetadata,
    );
    _debugTrace(method, step, safeMetadata);
  }

  static void _debugTrace(
    String method,
    String step,
    Map<String, Object?> metadata,
  ) {
    if (!kDebugMode ||
        !(step.contains('FAILED') ||
            step.contains('FALLBACK') ||
            step.contains('RESPONSE_RECEIVED') ||
            step.contains('RESPONSE_DECODED') ||
            step.contains('RESPONSE_VALIDATED') ||
            step == 'MEAL_PROMPT_BUDGET' ||
            step == 'EXERCISE_PROMPT_BUDGET' ||
            step == 'MEAL_FILTER_STARTED' ||
            step == 'MEAL_FILTER_COMPLETED' ||
            step == 'MEAL_COMPACT_SLOT_ALIGNMENT' ||
            step == 'LOCAL_INFERENCE_FAILED' ||
            step == 'LOCAL_INFERENCE_COMPLETED')) {
      return;
    }
    final fields = metadata.entries
        .map((entry) => '${entry.key}=${_debugValue(entry.value)}')
        .join(' ');
    // Only allowlisted metadata is mirrored. Prompt and model output text are
    // never included in a schedule diagnostic line.
    final line =
        '[NABI_AI_TRACE] method=${_debugToken(method)} '
        'step=${_debugToken(step)} $fields';
    debugPrint(line);
    _debugWriteChain = _debugWriteChain.then((_) async {
      try {
        final file = File(
          '${Directory.systemTemp.path}/nabi_ai_schedule_diagnostics.log',
        );
        if (await file.exists() && await file.length() > 65536) {
          await file.writeAsString('', flush: true);
        }
        await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
      } catch (_) {
        // Diagnostics must never interrupt schedule generation.
      }
    });
  }

  static String _debugValue(Object? value) {
    if (value is num || value is bool) return value.toString();
    if (value is String) return _debugToken(value);
    return 'omitted';
  }

  static String _debugToken(String value) => value
      .replaceAll(RegExp(r'[^A-Za-z0-9_.:=/,-]'), '_')
      .substring(0, value.length > 100 ? 100 : value.length);

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
