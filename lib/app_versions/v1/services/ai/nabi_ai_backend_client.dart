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

  const NabiAiBackendClient({
    this.clientOverride,
    this.functionName = 'nabi-ai-generate',
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
      'model': model,
      'contentsCount': contents.length,
      'maxOutputTokens': generationConfig.maxOutputTokens,
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
          'contents': contents.map((content) => content.toJson()).toList(),
          'generation_config': generationConfig.toJson(),
          if (systemInstruction != null)
            'system_instruction': systemInstruction,
        },
      );
      final data = response.data;
      if (data is Map && data['text'] is String) {
        final text = (data['text'] as String).trim();
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
      final exception = GeminiApiException(
        statusCode: error.status,
        status: 'backend_function_error',
        message: 'AI backend request failed.',
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
          'errorCode': 'backend_function_error',
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
}
