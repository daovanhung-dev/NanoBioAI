import 'dart:convert';

import 'package:flutter/foundation.dart';
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
      final errorDetails = _asBackendMap(error.details);
      final backendCode = _backendCode(errorDetails);
      final providerErrorCode = _providerErrorCode(errorDetails);
      final providerPhase = _providerPhase(errorDetails);
      final providerStatus = _providerStatus(errorDetails);
      final providerDiagnosticCode = [
        providerErrorCode,
        providerPhase,
        providerStatus,
      ].whereType<String>().join('_');
      _printBackendFailure(
        traceId: traceId,
        stage: 'FUNCTION_ERROR',
        model: model,
        statusCode: error.status,
        errorCode: providerDiagnosticCode.isNotEmpty
            ? providerDiagnosticCode
            : backendCode ?? 'backend_function_error',
        stackTrace: stackTrace,
      );
      final exception = GeminiApiException(
        statusCode: error.status,
        status: switch (backendCode) {
          'OUTPUT_TRUNCATED' => 'MAX_TOKENS',
          'MODEL_CONTEXT_LIMIT_EXCEEDED' => 'model_context_limit_exceeded',
          'REQUEST_TOO_LARGE' => 'request_too_large',
          'PROVIDER_RATE_LIMITED' => 'resource_exhausted',
          'PROVIDER_TIMEOUT' => 'provider_timeout',
          'PROVIDER_NETWORK_ERROR' => 'provider_network_error',
          'PROVIDER_TEMPORARY_FAILURE' => 'provider_temporary_failure',
          _ => 'backend_function_error',
        },
        backendErrorCode: providerDiagnosticCode.isNotEmpty
            ? providerDiagnosticCode
            : backendCode,
        message: switch (backendCode) {
          'OUTPUT_TRUNCATED' => 'AI did not complete the response.',
          'MODEL_CONTEXT_LIMIT_EXCEEDED' =>
            'Danh mục vượt quá giới hạn token của model AI đang cấu hình. Cần cập nhật model hoặc dung lượng context trước khi tạo lịch.',
          'REQUEST_TOO_LARGE' =>
            'Danh sách gửi đến AI vượt quá giới hạn dung lượng request. Cần điều chỉnh model hoặc cấu hình request trước khi tạo lịch.',
          'PROVIDER_RATE_LIMITED' =>
            'Nhà cung cấp AI đang giới hạn tần suất yêu cầu.',
          'PROVIDER_TIMEOUT' => 'Nhà cung cấp AI phản hồi quá thời gian chờ.',
          'PROVIDER_NETWORK_ERROR' => 'Không thể kết nối đến nhà cung cấp AI.',
          'PROVIDER_TEMPORARY_FAILURE' =>
            'Nhà cung cấp AI tạm thời chưa sẵn sàng.',
          _ => 'AI backend request failed.',
        },
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
              : backendCode == 'MODEL_CONTEXT_LIMIT_EXCEEDED'
              ? 'model_context_limit_exceeded'
              : backendCode == 'REQUEST_TOO_LARGE'
              ? 'request_too_large'
              : backendCode == 'PROVIDER_RATE_LIMITED'
              ? 'provider_rate_limited'
              : backendCode == 'PROVIDER_TIMEOUT'
              ? 'provider_timeout'
              : backendCode == 'PROVIDER_NETWORK_ERROR'
              ? 'provider_network_error'
              : backendCode == 'PROVIDER_TEMPORARY_FAILURE'
              ? 'provider_temporary_failure'
              : 'backend_function_error',
        },
        location: StackTrace.current,
      );
      Error.throwWithStackTrace(exception, stackTrace);
    } on GeminiApiException catch (error, stackTrace) {
      if (error.status != 'invalid_backend_response') {
        _printBackendFailure(
          traceId: traceId,
          stage: 'API_ERROR',
          model: model,
          statusCode: error.statusCode,
          errorCode: error.status ?? 'api_error',
          stackTrace: stackTrace,
        );
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
    } catch (error, stackTrace) {
      stopwatch.stop();
      _printBackendFailure(
        traceId: traceId,
        stage: 'NETWORK_ERROR',
        model: model,
        statusCode: 503,
        errorCode: error.runtimeType.toString(),
        stackTrace: stackTrace,
      );
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

  void _printBackendFailure({
    required String traceId,
    required String stage,
    required String model,
    required int? statusCode,
    required String errorCode,
    required StackTrace stackTrace,
  }) {
    if (!kDebugMode) return;
    final safeModel = model.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '');
    final safeCode = errorCode.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '');
    // ignore: avoid_print
    print(
      '[NABI_AI_SCHEDULE] component=AI_BACKEND traceId=$traceId '
      'stage=$stage function=$functionName model=$safeModel '
      'statusCode=${statusCode ?? 'none'} errorCode=$safeCode',
    );
    for (final line in stackTrace.toString().split('\n').take(8)) {
      if (line.trim().isEmpty) continue;
      // ignore: avoid_print
      print('[NABI_AI_SCHEDULE] stack=$line');
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

  static String? _providerErrorCode(Map<String, Object?>? value) {
    final code = value?['providerErrorCode']?.toString().trim();
    if (code == null || !RegExp(r'^provider_[a-z0-9_]{1,48}$').hasMatch(code)) {
      return null;
    }
    return code;
  }

  static String? _providerPhase(Map<String, Object?>? value) {
    final phase = value?['providerPhase']?.toString().trim();
    return phase == 'model_metadata' ||
            phase == 'count_tokens' ||
            phase == 'generate_content'
        ? phase
        : null;
  }

  static String? _providerStatus(Map<String, Object?>? value) {
    final status = value?['providerStatus']?.toString().trim();
    if (status == null || !RegExp(r'^[A-Z][A-Z0-9_]{0,63}$').hasMatch(status)) {
      return null;
    }
    return status;
  }
}
