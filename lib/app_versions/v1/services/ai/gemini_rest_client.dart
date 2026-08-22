import 'dart:convert';

import 'package:dio/dio.dart';

/// Hàm HTTP POST có thể được mock trong unit test.
typedef GeminiHttpPost =
    Future<GeminiHttpResponse> Function({
      required String url,
      required Map<String, String> headers,
      required Map<String, Object?> body,
    });

typedef GeminiHttpStreamPost =
    Future<GeminiHttpStreamResponse> Function({
      required String url,
      required Map<String, String> headers,
      required Map<String, Object?> body,
    });

class GeminiHttpResponse {
  final int statusCode;
  final Object? data;

  const GeminiHttpResponse({required this.statusCode, required this.data});
}

class GeminiHttpStreamResponse {
  final int statusCode;
  final Stream<List<int>> bytes;
  final Object? errorData;

  const GeminiHttpStreamResponse({
    required this.statusCode,
    required this.bytes,
    this.errorData,
  });
}

class GeminiContent {
  final String role;
  final String text;

  const GeminiContent({required this.role, required this.text});

  const GeminiContent.user(String text) : this(role: 'user', text: text);

  const GeminiContent.model(String text) : this(role: 'model', text: text);

  Map<String, Object?> toJson() {
    return {
      'role': role,
      'parts': [
        {'text': text},
      ],
    };
  }
}

class GeminiGenerationConfig {
  final int candidateCount;
  final int maxOutputTokens;
  final double temperature;
  final double topP;
  final String? responseMimeType;

  const GeminiGenerationConfig({
    this.candidateCount = 1,
    required this.maxOutputTokens,
    required this.temperature,
    required this.topP,
    this.responseMimeType,
  });

  Map<String, Object?> toJson() {
    final mimeType = _cleanText(responseMimeType);
    return {
      'candidateCount': candidateCount,
      'maxOutputTokens': maxOutputTokens,
      'temperature': temperature,
      'topP': topP,
      if (mimeType != null) 'responseMimeType': mimeType,
    };
  }
}

class GeminiApiException implements Exception {
  final int? statusCode;
  final String? status;
  final String message;

  const GeminiApiException({
    required this.message,
    this.statusCode,
    this.status,
  });

  bool get isAuthenticationFailure {
    final normalizedStatus = _cleanText(status)?.toLowerCase();
    return statusCode == 401 ||
        statusCode == 403 ||
        normalizedStatus == 'unauthenticated' ||
        normalizedStatus == 'permission_denied';
  }

  bool get isModelUnavailable {
    final normalizedStatus = _cleanText(status)?.toLowerCase();
    return statusCode == 404 || normalizedStatus == 'not_found';
  }

  bool get isNetworkFailure {
    final normalizedStatus = _cleanText(status)?.toLowerCase();
    return normalizedStatus == 'network_error' ||
        normalizedStatus == 'connection_timeout' ||
        normalizedStatus == 'send_timeout' ||
        normalizedStatus == 'receive_timeout' ||
        normalizedStatus == 'tls_error';
  }

  bool get isTransient {
    final code = statusCode;
    if (code == 408 || code == 429) return true;
    if (code != null && code >= 500) return true;

    final normalizedStatus = _cleanText(status)?.toLowerCase();
    return isNetworkFailure ||
        normalizedStatus == 'resource_exhausted' ||
        normalizedStatus == 'unavailable' ||
        normalizedStatus == 'deadline_exceeded' ||
        normalizedStatus == 'internal';
  }

  @override
  String toString() {
    final codeLabel = statusCode?.toString() ?? 'unknown';
    final statusLabel = _cleanText(status) ?? 'unknown';
    return 'GeminiApiException($codeLabel, $statusLabel): $message';
  }
}

class GeminiRestClient {
  static const String defaultBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  final String _apiKey;
  final String _baseUrl;
  final GeminiHttpPost _post;
  final GeminiHttpStreamPost _streamPost;

  GeminiRestClient({
    required String apiKey,
    String? baseUrl,
    Dio? dio,
    GeminiHttpPost? post,
    GeminiHttpStreamPost? streamPost,
  }) : _apiKey = _requireText(apiKey, 'GEMINI_API_KEY'),
       _baseUrl = _normalizeBaseUrl(baseUrl),
       _post = post ?? _createDioPost(dio),
       _streamPost = streamPost ?? _createDioStreamPost(dio);

  Future<String> generateText({
    required String model,
    required List<GeminiContent> contents,
    required GeminiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async {
    final normalizedModel = _normalizeModel(model);
    final requestBody = _buildRequestBody(
      contents: contents,
      generationConfig: generationConfig,
      systemInstruction: systemInstruction,
    );
    final endpoint =
        '$_baseUrl/models/${Uri.encodeComponent(normalizedModel)}:generateContent';

    final response = await _post(
      url: endpoint,
      headers: _headers(accept: Headers.jsonContentType),
      body: requestBody,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _exceptionFromPayload(response.data, statusCode: response.statusCode);
    }
    return _extractText(response.data);
  }

  /// True Gemini SSE streaming. Each yielded string is an incremental text
  /// fragment from `streamGenerateContent?alt=sse`.
  Stream<String> streamText({
    required String model,
    required List<GeminiContent> contents,
    required GeminiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async* {
    final normalizedModel = _normalizeModel(model);
    final requestBody = _buildRequestBody(
      contents: contents,
      generationConfig: generationConfig,
      systemInstruction: systemInstruction,
    );
    final endpoint =
        '$_baseUrl/models/${Uri.encodeComponent(normalizedModel)}'
        ':streamGenerateContent?alt=sse';

    final response = await _streamPost(
      url: endpoint,
      headers: _headers(accept: 'text/event-stream'),
      body: requestBody,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _exceptionFromPayload(
        response.errorData,
        statusCode: response.statusCode,
      );
    }

    final dataLines = <String>[];
    await for (final line in const LineSplitter().bind(
      utf8.decoder.bind(response.bytes),
    )) {
      if (line.isEmpty) {
        final delta = _decodeSseData(dataLines);
        dataLines.clear();
        if (delta != null && delta.isNotEmpty) yield delta;
        continue;
      }
      if (line.startsWith(':')) continue;
      if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }

    final delta = _decodeSseData(dataLines);
    if (delta != null && delta.isNotEmpty) yield delta;
  }

  Map<String, String> _headers({required String accept}) {
    return {
      'x-goog-api-key': _apiKey,
      'Content-Type': Headers.jsonContentType,
      'Accept': accept,
    };
  }

  static Map<String, Object?> _buildRequestBody({
    required List<GeminiContent> contents,
    required GeminiGenerationConfig generationConfig,
    String? systemInstruction,
  }) {
    if (contents.isEmpty) {
      throw const GeminiApiException(
        message: 'Gemini request requires at least one content item.',
      );
    }

    final requestBody = <String, Object?>{
      'contents': contents
          .map((content) => content.toJson())
          .toList(growable: false),
      'generationConfig': generationConfig.toJson(),
    };
    final normalizedInstruction = _cleanText(systemInstruction);
    if (normalizedInstruction != null) {
      requestBody['systemInstruction'] = {
        'parts': [
          {'text': normalizedInstruction},
        ],
      };
    }
    return requestBody;
  }

  static String? _decodeSseData(List<String> dataLines) {
    if (dataLines.isEmpty) return null;
    final raw = dataLines.join('\n').trim();
    if (raw.isEmpty || raw == '[DONE]') return null;

    final Object? payload;
    try {
      payload = jsonDecode(raw);
    } on FormatException catch (error) {
      throw GeminiApiException(
        status: 'invalid_stream_event',
        message: _truncateText('Invalid Gemini SSE event: $error', 240),
      );
    }

    final rootMap = _asObjectMap(payload);
    if (rootMap?['error'] != null) {
      throw _exceptionFromPayload(payload);
    }

    final candidates = rootMap?['candidates'];
    if (candidates is List) {
      final fragments = <String>[];
      for (final candidate in candidates) {
        final candidateMap = _asObjectMap(candidate);
        final contentMap = _asObjectMap(candidateMap?['content']);
        final parts = contentMap?['parts'];
        if (parts is! List) continue;
        for (final part in parts) {
          final partMap = _asObjectMap(part);
          final value = partMap?['text'];
          if (value is String && value.isNotEmpty) fragments.add(value);
        }
      }
      if (fragments.isNotEmpty) return fragments.join();
    }

    final promptFeedback = _asObjectMap(rootMap?['promptFeedback']);
    final blockReason = _cleanText(promptFeedback?['blockReason']?.toString());
    if (blockReason != null) {
      throw GeminiApiException(
        status: 'blocked',
        message: 'Gemini blocked the request: $blockReason.',
      );
    }

    // A terminal SSE event may only contain finishReason/usage metadata.
    return null;
  }

  static GeminiHttpPost _createDioPost(Dio? injectedDio) {
    final dio = injectedDio ?? _newDio();
    return ({
      required String url,
      required Map<String, String> headers,
      required Map<String, Object?> body,
    }) async {
      try {
        final response = await dio.post<Object?>(
          url,
          data: body,
          options: Options(
            headers: headers,
            contentType: Headers.jsonContentType,
            responseType: ResponseType.json,
          ),
        );
        return GeminiHttpResponse(
          statusCode: response.statusCode ?? 200,
          data: response.data,
        );
      } on DioException catch (error, stackTrace) {
        final exception = _exceptionFromPayload(
          error.response?.data,
          statusCode: error.response?.statusCode,
          fallbackStatus: _safeDioStatus(error),
          fallbackMessage: _safeDioMessage(error),
        );
        Error.throwWithStackTrace(exception, stackTrace);
      } catch (error, stackTrace) {
        Error.throwWithStackTrace(
          GeminiApiException(
            message: _truncateText('Unexpected Gemini client error: $error', 240),
          ),
          stackTrace,
        );
      }
    };
  }

  static GeminiHttpStreamPost _createDioStreamPost(Dio? injectedDio) {
    final dio = injectedDio ?? _newDio();
    return ({
      required String url,
      required Map<String, String> headers,
      required Map<String, Object?> body,
    }) async {
      final cancelToken = CancelToken();
      try {
        final response = await dio.post<ResponseBody>(
          url,
          data: body,
          cancelToken: cancelToken,
          options: Options(
            headers: headers,
            contentType: Headers.jsonContentType,
            responseType: ResponseType.stream,
          ),
        );
        final bodyStream = response.data;
        if (bodyStream == null) {
          throw const GeminiApiException(
            status: 'empty_stream',
            message: 'Gemini returned an empty streaming response.',
          );
        }

        Stream<List<int>> bytes() async* {
          try {
            await for (final chunk in bodyStream.stream) {
              yield chunk;
            }
          } finally {
            if (!cancelToken.isCancelled) cancelToken.cancel('stream_closed');
          }
        }

        return GeminiHttpStreamResponse(
          statusCode: response.statusCode ?? 200,
          bytes: bytes(),
        );
      } on DioException catch (error, stackTrace) {
        final exception = _exceptionFromPayload(
          null,
          statusCode: error.response?.statusCode,
          fallbackStatus: _safeDioStatus(error),
          fallbackMessage: _safeDioMessage(error),
        );
        Error.throwWithStackTrace(exception, stackTrace);
      } catch (error, stackTrace) {
        if (error is GeminiApiException) rethrow;
        Error.throwWithStackTrace(
          GeminiApiException(
            message: _truncateText('Unexpected Gemini stream error: $error', 240),
          ),
          stackTrace,
        );
      }
    };
  }

  static Dio _newDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
  }

  static GeminiApiException _exceptionFromPayload(
    Object? payload, {
    int? statusCode,
    String? fallbackStatus,
    String? fallbackMessage,
  }) {
    final rootMap = _asObjectMap(payload);
    final errorMap = _asObjectMap(rootMap?['error']);
    final status =
        _cleanText(errorMap?['status']?.toString()) ?? _cleanText(fallbackStatus);
    final message =
        _cleanText(errorMap?['message']?.toString()) ??
        _cleanText(rootMap?['message']?.toString()) ??
        _cleanText(fallbackMessage) ??
        'Gemini request failed.';
    return GeminiApiException(
      statusCode: statusCode,
      status: status,
      message: _truncateText(message, 240),
    );
  }

  static String _extractText(Object? payload) {
    final rootMap = _asObjectMap(payload);
    final candidates = rootMap?['candidates'];
    if (candidates is List) {
      final textSegments = <String>[];
      for (final candidate in candidates) {
        final candidateMap = _asObjectMap(candidate);
        final contentMap = _asObjectMap(candidateMap?['content']);
        final parts = contentMap?['parts'];
        if (parts is! List) continue;
        for (final part in parts) {
          final partMap = _asObjectMap(part);
          final text = _cleanText(partMap?['text']?.toString());
          if (text != null) textSegments.add(text);
        }
      }
      final result = textSegments.join('\n').trim();
      if (result.isNotEmpty) return result;

      final finishReason = _extractFinishReason(candidates);
      if (finishReason != null) {
        throw GeminiApiException(
          status: finishReason,
          message: 'Gemini did not return text. Finish reason: $finishReason.',
        );
      }
    }

    final promptFeedback = _asObjectMap(rootMap?['promptFeedback']);
    final blockReason = _cleanText(promptFeedback?['blockReason']?.toString());
    if (blockReason != null) {
      throw GeminiApiException(
        status: 'blocked',
        message: 'Gemini blocked the request: $blockReason.',
      );
    }
    throw const GeminiApiException(message: 'Gemini returned an empty response.');
  }

  static String? _extractFinishReason(List<Object?> candidates) {
    for (final candidate in candidates) {
      final candidateMap = _asObjectMap(candidate);
      final finishReason = _cleanText(candidateMap?['finishReason']?.toString());
      if (finishReason != null) return finishReason;
    }
    return null;
  }

  static String _safeDioStatus(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout => 'connection_timeout',
      DioExceptionType.sendTimeout => 'send_timeout',
      DioExceptionType.receiveTimeout => 'receive_timeout',
      DioExceptionType.connectionError => 'network_error',
      DioExceptionType.badCertificate => 'tls_error',
      DioExceptionType.cancel => 'cancelled',
      DioExceptionType.badResponse => 'bad_response',
      DioExceptionType.unknown => 'network_error',
    };
  }

  static String _safeDioMessage(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout => 'Gemini connection timed out.',
      DioExceptionType.sendTimeout => 'Gemini request timed out while sending.',
      DioExceptionType.receiveTimeout => 'Gemini response timed out.',
      DioExceptionType.connectionError => 'Could not connect to Gemini.',
      DioExceptionType.badCertificate => 'Gemini TLS certificate was rejected.',
      DioExceptionType.cancel => 'Gemini request was cancelled.',
      DioExceptionType.badResponse => 'Gemini returned an invalid HTTP response.',
      DioExceptionType.unknown =>
        'Gemini request failed because of an unknown network error.',
    };
  }

  static String _normalizeBaseUrl(String? value) {
    final normalizedUrl = _cleanText(value) ?? defaultBaseUrl;
    return normalizedUrl.endsWith('/')
        ? normalizedUrl.substring(0, normalizedUrl.length - 1)
        : normalizedUrl;
  }

  static String _normalizeModel(String value) {
    final normalizedModel = _requireText(value, 'Gemini model');
    const prefix = 'models/';
    return normalizedModel.startsWith(prefix)
        ? normalizedModel.substring(prefix.length)
        : normalizedModel;
  }
}

Map<String, Object?>? _asObjectMap(Object? value) {
  if (value is! Map) return null;
  return Map<String, Object?>.fromEntries(
    value.entries.map((entry) => MapEntry(entry.key.toString(), entry.value)),
  );
}

String? _cleanText(String? value) {
  final cleaned = value?.trim();
  return cleaned == null || cleaned.isEmpty ? null : cleaned;
}

String _requireText(String value, String label) {
  final cleaned = value.trim();
  if (cleaned.isEmpty) {
    throw ArgumentError.value(value, label, '$label must not be empty.');
  }
  return cleaned;
}

String _truncateText(String value, int maxLength) {
  if (value.length <= maxLength) return value;
  return '${value.substring(0, maxLength)}…';
}
