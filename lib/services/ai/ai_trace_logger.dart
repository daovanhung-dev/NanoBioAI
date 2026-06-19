import 'dart:convert';

import 'package:nano_app/core/utils/logger/app_logger.dart';

class AITraceLogger {
  static const aiGen = 'AI_GEN';
  static const localGen = 'LOCAL_GEN';
  static const _chunkLength = 3500;

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
    AppLogger.success(
      tag,
      _line(traceId, method, step, message, location: location),
    );
    if (data.isNotEmpty) {
      payload(tag, traceId, method, '$step.data', data, location: location);
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
    AppLogger.info(
      tag,
      _line(traceId, method, step, message, location: location),
    );
    if (data.isNotEmpty) {
      payload(tag, traceId, method, '$step.data', data, location: location);
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
    AppLogger.warning(
      tag,
      _line(traceId, method, step, message, location: location),
    );
    if (data.isNotEmpty) {
      payload(tag, traceId, method, '$step.data', data, location: location);
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
    AppLogger.error(
      tag,
      _line(traceId, method, step, message, location: location),
      error,
      stackTrace,
    );
    if (data.isNotEmpty) {
      payload(tag, traceId, method, '$step.data', data, location: location);
    }
  }

  static void payload(
    String tag,
    String traceId,
    String method,
    String step,
    Object? value, {
    StackTrace? location,
  }) {
    final encoded = _encode(value);
    if (encoded.length <= _chunkLength) {
      AppLogger.info(
        tag,
        _line(traceId, method, step, encoded, location: location),
      );
      return;
    }

    final totalChunks = (encoded.length / _chunkLength).ceil();
    for (var index = 0; index < totalChunks; index++) {
      final start = index * _chunkLength;
      final end = start + _chunkLength > encoded.length
          ? encoded.length
          : start + _chunkLength;
      AppLogger.info(
        tag,
        _line(
          traceId,
          method,
          '$step chunk=${index + 1}/$totalChunks length=${encoded.length}',
          encoded.substring(start, end),
          location: location,
        ),
      );
    }
  }

  static String _line(
    String traceId,
    String method,
    String step,
    String message, {
    StackTrace? location,
  }) {
    return 'traceId=$traceId method=$method step=$step '
        'location=${_location(location)} $message';
  }

  static String _location(StackTrace? stackTrace) {
    final text = stackTrace?.toString().trim();
    if (text == null || text.isEmpty) {
      return 'unknown';
    }
    return text.split('\n').first.trim();
  }

  static String _encode(Object? value) {
    if (value is String) {
      return value;
    }

    try {
      return const JsonEncoder.withIndent('  ').convert(_jsonSafe(value));
    } catch (_) {
      return value.toString();
    }
  }

  static Object? _jsonSafe(Object? value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _jsonSafe(entry.value),
      };
    }
    if (value is Iterable) {
      return value.map(_jsonSafe).toList(growable: false);
    }
    return value.toString();
  }
}
