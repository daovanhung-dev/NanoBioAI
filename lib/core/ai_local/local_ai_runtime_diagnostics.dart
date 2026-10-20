import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../utils/logger/app_log_category.dart';
import '../utils/logger/app_log_level.dart';
import '../utils/logger/app_logger.dart';

/// Carries a safe request correlation id through local AI runtime calls.
///
/// The value is diagnostic metadata only; prompts and generated text are never
/// stored in the zone.
abstract final class LocalAiRuntimeDiagnostics {
  static final Object _traceIdZoneKey = Object();
  static const _safeMetadataKeys = <String>{
    'availableTokens',
    'candidateCount',
    'candidateGroups',
    'contextSize',
    'durationMs',
    'errorCode',
    'errorType',
    'firstTokenMs',
    'hasSystemInstruction',
    'inferenceDurationMs',
    'inferenceThreads',
    'inputTokens',
    'maxOutputTokens',
    'model',
    'outputReserveTokens',
    'outputTokens',
    'queueWaitMs',
    'status',
    'streamBatchTokenThreshold',
    'tokenizationDurationMs',
  };
  static int _traceSequence = 0;
  static Future<void> _debugWriteChain = Future<void>.value();

  static Future<T> withTraceId<T>(
    String traceId,
    Future<T> Function() action,
  ) => runZoned<Future<T>>(action, zoneValues: {_traceIdZoneKey: traceId});

  static String? get currentTraceId {
    final value = Zone.current[_traceIdZoneKey];
    return value is String ? value : null;
  }

  static String newTraceId(String scope) {
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final sequence = (++_traceSequence).toString().padLeft(4, '0');
    return '$scope-$timestamp-$sequence';
  }

  static void info({
    required String traceId,
    required String operation,
    required String message,
    Map<String, Object?> data = const {},
  }) => _write(
    level: AppLogLevel.debug,
    traceId: traceId,
    operation: operation,
    message: message,
    data: data,
  );

  static void warning({
    required String traceId,
    required String operation,
    required String message,
    Map<String, Object?> data = const {},
  }) => _write(
    level: AppLogLevel.warn,
    traceId: traceId,
    operation: operation,
    message: message,
    data: data,
  );

  static void _write({
    required AppLogLevel level,
    required String traceId,
    required String operation,
    required String message,
    required Map<String, Object?> data,
  }) {
    final metadata = <String, Object?>{};
    for (final entry in data.entries) {
      if (!_safeMetadataKeys.contains(entry.key)) continue;
      final value = entry.value;
      if (value is num || value is bool || value is String) {
        metadata[entry.key] = value;
      }
    }
    AppLogger.event(
      level: level,
      category: AppLogCategory.ai,
      scope: 'LOCAL_AI_RUNTIME',
      operation: operation,
      message: message,
      correlationId: traceId,
      metadata: metadata,
    );
    _debugWrite(operation, metadata);
  }

  static void _debugWrite(String operation, Map<String, Object?> metadata) {
    if (!kDebugMode || !operation.contains('LOCAL_INFERENCE')) return;
    String token(Object? value) => value
        .toString()
        .replaceAll(RegExp(r'[^A-Za-z0-9_.:=/,-]'), '_')
        .substring(
          0,
          value.toString().length > 100 ? 100 : value.toString().length,
        );
    final fields = metadata.entries
        .map((entry) => '${entry.key}=${token(entry.value)}')
        .join(' ');
    final line = '[NABI_AI_RUNTIME] operation=${token(operation)} $fields';
    debugPrint(line);
    _debugWriteChain = _debugWriteChain.then((_) async {
      try {
        final file = File(
          '${Directory.systemTemp.path}/nabi_ai_local_runtime.log',
        );
        if (await file.exists() && await file.length() > 65536) {
          await file.writeAsString('', flush: true);
        }
        await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
      } catch (_) {
        // Diagnostics must never interrupt local inference.
      }
    });
  }
}
