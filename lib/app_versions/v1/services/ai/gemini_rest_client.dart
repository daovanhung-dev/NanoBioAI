import 'package:dio/dio.dart';

/// Hàm HTTP POST có thể được mock trong unit test.
typedef GeminiHttpPost =
    Future<GeminiHttpResponse> Function({
      required String url,
      required Map<String, String> headers,
      required Map<String, Object?> body,
    });

/// Kết quả HTTP tối giản để tách Gemini client khỏi Dio.
class GeminiHttpResponse {
  final int statusCode;
  final Object? data;

  const GeminiHttpResponse({required this.statusCode, required this.data});
}

/// Một nội dung hội thoại gửi tới Gemini.
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

/// Cấu hình sinh nội dung của Gemini.
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

/// Lỗi được trả về từ Gemini API hoặc lỗi kết nối mạng.
class GeminiApiException implements Exception {
  final int? statusCode;
  final String? status;
  final String message;

  const GeminiApiException({
    required this.message,
    this.statusCode,
    this.status,
  });

  /// Xác định lỗi có thể thử lại hay không.
  bool get isTransient {
    final code = statusCode;

    if (code == 408 || code == 429) {
      return true;
    }

    if (code != null && code >= 500) {
      return true;
    }

    final normalizedStatus = _cleanText(status)?.toLowerCase();

    return normalizedStatus == 'resource_exhausted' ||
        normalizedStatus == 'unavailable' ||
        normalizedStatus == 'deadline_exceeded' ||
        normalizedStatus == 'internal';
  }

  @override
  String toString() {
    final codeLabel = statusCode?.toString() ?? 'unknown';
    final statusLabel = _cleanText(status) ?? 'unknown';

    return 'GeminiApiException('
        '$codeLabel, '
        '$statusLabel'
        '): $message';
  }
}

/// REST client dùng để gọi Gemini Generate Content API.
class GeminiRestClient {
  static const String defaultBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  final String _apiKey;
  final String _baseUrl;
  final GeminiHttpPost _post;

  GeminiRestClient({
    required String apiKey,
    String? baseUrl,
    Dio? dio,
    GeminiHttpPost? post,
  }) : _apiKey = _requireText(apiKey, 'GEMINI_API_KEY'),
       _baseUrl = _normalizeBaseUrl(baseUrl),
       _post = post ?? _createDioPost(dio);

  /// Gửi yêu cầu sinh văn bản tới Gemini.
  Future<String> generateText({
    required String model,
    required List<GeminiContent> contents,
    required GeminiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async {
    final normalizedModel = _normalizeModel(model);

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

    final endpoint =
        '$_baseUrl/models/'
        '${Uri.encodeComponent(normalizedModel)}'
        ':generateContent';

    final response = await _post(
      url: endpoint,
      headers: {
        'x-goog-api-key': _apiKey,
        'Content-Type': Headers.jsonContentType,
        'Accept': Headers.jsonContentType,
      },
      body: requestBody,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _exceptionFromPayload(
        response.data,
        statusCode: response.statusCode,
      );
    }

    return _extractText(response.data);
  }

  /// Tạo implementation HTTP bằng Dio.
  static GeminiHttpPost _createDioPost(Dio? injectedDio) {
    final dio =
        injectedDio ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(minutes: 2),
            responseType: ResponseType.json,
          ),
        );

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
        final response = error.response;

        final exception = _exceptionFromPayload(
          response?.data,
          statusCode: response?.statusCode,
          fallbackMessage: _safeDioMessage(error),
        );

        Error.throwWithStackTrace(exception, stackTrace);
      } catch (error, stackTrace) {
        final exception = GeminiApiException(
          message: _truncateText('Unexpected Gemini client error: $error', 240),
        );

        Error.throwWithStackTrace(exception, stackTrace);
      }
    };
  }

  /// Chuyển payload lỗi của Gemini thành GeminiApiException.
  static GeminiApiException _exceptionFromPayload(
    Object? payload, {
    int? statusCode,
    String? fallbackMessage,
  }) {
    final rootMap = _asObjectMap(payload);
    final errorMap = _asObjectMap(rootMap?['error']);

    final status = _cleanText(errorMap?['status']?.toString());

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

  /// Trích xuất toàn bộ văn bản trong candidates.
  static String _extractText(Object? payload) {
    final rootMap = _asObjectMap(payload);
    final candidates = rootMap?['candidates'];

    if (candidates is List) {
      final textSegments = <String>[];

      for (final candidate in candidates) {
        final candidateMap = _asObjectMap(candidate);
        final contentMap = _asObjectMap(candidateMap?['content']);
        final parts = contentMap?['parts'];

        if (parts is! List) {
          continue;
        }

        for (final part in parts) {
          final partMap = _asObjectMap(part);
          final text = _cleanText(partMap?['text']?.toString());

          if (text != null) {
            textSegments.add(text);
          }
        }
      }

      final result = textSegments.join('\n').trim();

      if (result.isNotEmpty) {
        return result;
      }

      final finishReason = _extractFinishReason(candidates);

      if (finishReason != null) {
        throw GeminiApiException(
          status: finishReason,
          message:
              'Gemini did not return text. '
              'Finish reason: $finishReason.',
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

    throw const GeminiApiException(
      message: 'Gemini returned an empty response.',
    );
  }

  /// Lấy finishReason đầu tiên từ danh sách candidates.
  static String? _extractFinishReason(List<Object?> candidates) {
    for (final candidate in candidates) {
      final candidateMap = _asObjectMap(candidate);

      final finishReason = _cleanText(
        candidateMap?['finishReason']?.toString(),
      );

      if (finishReason != null) {
        return finishReason;
      }
    }

    return null;
  }

  /// Chuyển lỗi Dio thành thông báo không chứa dữ liệu nhạy cảm.
  static String _safeDioMessage(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout => 'Gemini connection timed out.',

      DioExceptionType.sendTimeout => 'Gemini request timed out while sending.',

      DioExceptionType.receiveTimeout => 'Gemini response timed out.',

      DioExceptionType.connectionError => 'Could not connect to Gemini.',

      DioExceptionType.badCertificate => 'Gemini TLS certificate was rejected.',

      DioExceptionType.cancel => 'Gemini request was cancelled.',

      DioExceptionType.badResponse =>
        'Gemini returned an invalid HTTP response.',

      DioExceptionType.unknown =>
        'Gemini request failed because of an unknown network error.',
    };
  }

  /// Chuẩn hóa URL và xóa dấu / ở cuối.
  static String _normalizeBaseUrl(String? value) {
    final normalizedUrl = _cleanText(value) ?? defaultBaseUrl;

    if (normalizedUrl.endsWith('/')) {
      return normalizedUrl.substring(0, normalizedUrl.length - 1);
    }

    return normalizedUrl;
  }

  /// Chấp nhận cả gemini-x và models/gemini-x.
  static String _normalizeModel(String value) {
    final normalizedModel = _requireText(value, 'Gemini model');

    const prefix = 'models/';

    if (normalizedModel.startsWith(prefix)) {
      return normalizedModel.substring(prefix.length);
    }

    return normalizedModel;
  }
}

/// Chuyển map không xác định kiểu thành map có khóa chuỗi.
Map<String, Object?>? _asObjectMap(Object? value) {
  if (value is! Map) {
    return null;
  }

  return Map<String, Object?>.fromEntries(
    value.entries.map((entry) => MapEntry(entry.key.toString(), entry.value)),
  );
}

/// Xóa khoảng trắng và trả null nếu chuỗi rỗng.
String? _cleanText(String? value) {
  final cleaned = value?.trim();

  if (cleaned == null || cleaned.isEmpty) {
    return null;
  }

  return cleaned;
}

/// Yêu cầu một giá trị chuỗi bắt buộc.
String _requireText(String value, String label) {
  final cleaned = value.trim();

  if (cleaned.isEmpty) {
    throw ArgumentError.value(value, label, '$label must not be empty.');
  }

  return cleaned;
}

/// Giới hạn độ dài thông báo lỗi.
String _truncateText(String value, int maxLength) {
  if (value.length <= maxLength) {
    return value;
  }

  return '${value.substring(0, maxLength)}…';
}
