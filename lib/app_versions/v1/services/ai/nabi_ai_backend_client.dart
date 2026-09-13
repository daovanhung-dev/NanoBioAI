import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'ai_trace_logger.dart';
import 'gemini_rest_client.dart';

/// Production AI transport. The Flutter client sends only bounded prompt
/// content to a Supabase Edge Function; the Gemini credential is held by the
/// function environment and never enters the app process.
class NabiAiBackendClient implements AiTextClient {
  static const _tag = 'AI_BACKEND';

  final SupabaseClient? clientOverride;
  final String functionName;
  final String? operation;

  const NabiAiBackendClient({
    this.clientOverride,
    this.functionName = 'nabi-ai-generate',
    this.operation,
  });

  SupabaseClient? get _client {
    if (clientOverride != null) return clientOverride;
    try {
      return Supabase.instance.client;
    } on AssertionError {
      return null;
    }
  }

  @override
  Future<String> generateText({
    required String model,
    required List<GeminiContent> contents,
    required GeminiGenerationConfig generationConfig,
    String? systemInstruction,
  }) {
    return _invoke(
      model: model,
      contents: contents,
      generationConfig: generationConfig,
      systemInstruction: systemInstruction,
      streaming: false,
    );
  }

  Future<String> _invoke({
    required String model,
    required List<GeminiContent> contents,
    required GeminiGenerationConfig generationConfig,
    required String? systemInstruction,
    required bool streaming,
  }) async {
    final traceId = AITraceLogger.nextTraceId('ai-backend');
    const method = 'generateText';
    final stopwatch = Stopwatch()..start();
    final baseMetadata = <String, Object?>{
      'functionName': functionName,
      if (operation != null) 'operation': operation,
      'model': model,
      'contentsCount': contents.length,
      'hasSystemInstruction':
          systemInstruction != null && systemInstruction.trim().isNotEmpty,
      'streaming': streaming,
    };

    AITraceLogger.start(
      _tag,
      traceId,
      method,
      data: baseMetadata,
      location: StackTrace.current,
    );

    final client = _client;
    if (client == null) {
      stopwatch.stop();
      const exception = GeminiApiException(
        statusCode: 503,
        status: 'backend_unavailable',
        message: 'AI backend is not configured.',
      );
      AITraceLogger.error(
        _tag,
        traceId,
        method,
        'BACKEND_UNAVAILABLE',
        'AI backend is not configured.',
        exception,
        StackTrace.current,
        data: {
          ...baseMetadata,
          'durationMs': stopwatch.elapsedMilliseconds,
          'statusCode': exception.statusCode,
          'status': exception.status,
          'errorCode': 'backend_unavailable',
        },
        location: StackTrace.current,
      );
      throw exception;
    }

    try {
      final response = await client.functions.invoke(
        functionName,
        headers: {'x-ai-trace-id': traceId},
        body: {
          'model': model,
          if (operation != null) 'operation': operation,
          'contents': contents.map((content) => content.toJson()).toList(),
          'generation_config': generationConfig.toJson(),
          if (systemInstruction != null)
            'system_instruction': systemInstruction,
        },
      );
      final data = _decodeResponseData(response.data);
      final dataMap = _asBackendMap(data);
      final backendCode = _backendCode(dataMap);
      if (backendCode == 'OUTPUT_TRUNCATED') {
        throw GeminiApiException(
          statusCode: response.status,
          status: 'MAX_TOKENS',
          message: 'AI did not complete the response.',
        );
      }
      final text = dataMap?['text'] is String
          ? (dataMap?['text'] as String).trim()
          : data is String
          ? data.trim()
          : '';
      if (text.isNotEmpty) {
        stopwatch.stop();
        AITraceLogger.success(
          _tag,
          traceId,
          method,
          'SUCCESS',
          'AI backend request completed.',
          data: {
            ...baseMetadata,
            'durationMs': stopwatch.elapsedMilliseconds,
            'statusCode': response.status,
            'responseLength': text.length,
          },
          location: StackTrace.current,
        );
        return text;
      }

      stopwatch.stop();
      final exception = GeminiApiException(
        statusCode: response.status,
        status: 'invalid_backend_response',
        message: 'AI backend returned an invalid response.',
      );
      AITraceLogger.error(
        _tag,
        traceId,
        method,
        'INVALID_RESPONSE',
        'AI backend returned an invalid response.',
        exception,
        StackTrace.current,
        data: {
          ...baseMetadata,
          'durationMs': stopwatch.elapsedMilliseconds,
          'statusCode': response.status,
          'status': exception.status,
          'errorCode': 'invalid_backend_response',
        },
        location: StackTrace.current,
      );
      throw exception;
    } on FunctionException catch (error, stackTrace) {
      stopwatch.stop();
      final backendCode = _backendCode(_asBackendMap(error.details));
      final exception = GeminiApiException(
        statusCode: error.status,
        status: backendCode == 'OUTPUT_TRUNCATED'
            ? 'MAX_TOKENS'
            : 'backend_function_error',
        message: backendCode == 'OUTPUT_TRUNCATED'
            ? 'AI did not complete the response.'
            : 'AI backend request failed.',
      );
      AITraceLogger.error(
        _tag,
        traceId,
        method,
        'FUNCTION_ERROR',
        'AI backend function request failed.',
        exception,
        stackTrace,
        data: {
          ...baseMetadata,
          'durationMs': stopwatch.elapsedMilliseconds,
          'statusCode': error.status,
          'status': exception.status,
          'errorCode': backendCode == 'OUTPUT_TRUNCATED'
              ? 'output_truncated'
              : 'backend_function_error',
        },
        location: StackTrace.current,
      );
      Error.throwWithStackTrace(exception, stackTrace);
    } on GeminiApiException catch (error, stackTrace) {
      if (error.status != 'invalid_backend_response') {
        stopwatch.stop();
        AITraceLogger.error(
          _tag,
          traceId,
          method,
          'API_ERROR',
          'AI backend request failed with a normalized API error.',
          error,
          stackTrace,
          data: {
            ...baseMetadata,
            'durationMs': stopwatch.elapsedMilliseconds,
            'statusCode': error.statusCode,
            'status': error.status,
            'errorCode': error.status ?? 'api_error',
          },
          location: StackTrace.current,
        );
      }
      rethrow;
    } catch (_, stackTrace) {
      stopwatch.stop();
      const exception = GeminiApiException(
        statusCode: 503,
        status: 'network_error',
        message: 'AI backend request could not be completed.',
      );
      AITraceLogger.error(
        _tag,
        traceId,
        method,
        'NETWORK_ERROR',
        'AI backend request could not be completed.',
        exception,
        stackTrace,
        data: {
          ...baseMetadata,
          'durationMs': stopwatch.elapsedMilliseconds,
          'statusCode': exception.statusCode,
          'status': exception.status,
          'errorCode': 'network_error',
        },
        location: StackTrace.current,
      );
      Error.throwWithStackTrace(exception, stackTrace);
    }
  }

  /// The Edge Function currently returns a bounded complete response. Expose
  /// it through the existing stream contract so callers retain one API while
  /// no provider endpoint or credential is reachable from the client.
  @override
  Stream<String> streamText({
    required String model,
    required List<GeminiContent> contents,
    required GeminiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async* {
    yield await _invoke(
      model: model,
      contents: contents,
      generationConfig: generationConfig,
      systemInstruction: systemInstruction,
      streaming: true,
    );
  }

  static Object? _decodeResponseData(Object? value) {
    if (value is! String) return value;
    try {
      return jsonDecode(value);
    } on FormatException {
      return value;
    }
  }

  static Map<String, Object?>? _asBackendMap(Object? value) {
    final decoded = _decodeResponseData(value);
    if (decoded is! Map) return null;
    return Map<String, Object?>.fromEntries(
      decoded.entries.map(
        (entry) => MapEntry(entry.key.toString(), entry.value),
      ),
    );
  }

  static String? _backendCode(Map<String, Object?>? value) {
    final code = value?['code']?.toString().trim();
    return code == null || code.isEmpty ? null : code;
  }
}
