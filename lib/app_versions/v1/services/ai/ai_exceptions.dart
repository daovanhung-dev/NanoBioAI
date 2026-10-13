import 'dart:async';

import 'gemini_rest_client.dart';

class AIConfigurationUnavailableException implements Exception {
  static const userMessage =
      'Nabi chưa sẵn sàng trò chuyện lúc này. Bạn thử lại sau một chút nhé.';

  const AIConfigurationUnavailableException();

  @override
  String toString() => userMessage;
}

class AIResponseInvalidException implements Exception {
  static const userMessage =
      'Nabi chưa nhận được câu trả lời phù hợp lúc này. Bạn thử lại sau một chút nhé.';

  const AIResponseInvalidException();

  @override
  String toString() => userMessage;
}

class AIAuthenticationException implements Exception {
  static const userMessage =
      'Nabi chưa thể khởi động dịch vụ lúc này. Bạn thử mở lại ứng dụng nhé.';

  const AIAuthenticationException();

  static bool matches(Object error) {
    return error is GeminiApiException && error.isAuthenticationFailure;
  }

  @override
  String toString() => userMessage;
}

class AINetworkException implements Exception {
  static const userMessage =
      'Nabi chưa thể kết nối. Bạn kiểm tra mạng rồi thử lại nhé.';

  const AINetworkException();

  static bool matches(Object error) {
    if (error is TimeoutException) return true;
    return error is GeminiApiException && error.isNetworkFailure;
  }

  @override
  String toString() => userMessage;
}

class AIModelUnavailableException implements Exception {
  static const userMessage =
      'Nabi hiện chưa sẵn sàng. Bạn thử lại sau một chút nhé.';

  const AIModelUnavailableException();

  static bool matches(Object error) {
    return error is GeminiApiException && error.isModelUnavailable;
  }

  @override
  String toString() => userMessage;
}

class AIModelContextLimitException implements Exception {
  static const userMessage =
      'Danh mục vượt quá giới hạn token của model AI đang cấu hình. Cần cập nhật model hoặc dung lượng context trước khi tạo lịch.';

  const AIModelContextLimitException();

  static bool matches(Object error) {
    return error is GeminiApiException &&
        error.status?.trim().toLowerCase() == 'model_context_limit_exceeded';
  }

  @override
  String toString() => userMessage;
}

class AIRequestTooLargeException implements Exception {
  static const userMessage =
      'Danh sách gửi đến AI vượt quá giới hạn dung lượng request. Cần điều chỉnh model hoặc cấu hình request trước khi tạo lịch.';

  const AIRequestTooLargeException();

  static bool matches(Object error) {
    return error is GeminiApiException &&
        error.status?.trim().toLowerCase() == 'request_too_large';
  }

  @override
  String toString() => userMessage;
}

class AIOverloadedException implements Exception {
  static const userMessage = 'Nabi đang bận. Bạn thử lại sau nhé.';

  final int? providerStatusCode;
  final String? providerStatus;
  final String? providerErrorCode;

  const AIOverloadedException({
    this.providerStatusCode,
    this.providerStatus,
    this.providerErrorCode,
  });

  static bool matches(Object error) {
    if (error is TimeoutException) {
      return true;
    }

    if (error is GeminiApiException && error.isTransient) {
      return true;
    }

    final normalized = error.toString().toLowerCase();

    return normalized.contains('overload') ||
        RegExp(r'server error \[(408|429|5\d\d)\]').hasMatch(normalized) ||
        normalized.contains('unavailable') ||
        normalized.contains('resource_exhausted') ||
        normalized.contains('resource has been exhausted') ||
        normalized.contains('deadline_exceeded') ||
        normalized.contains('quota') ||
        normalized.contains('rate limit') ||
        normalized.contains('too many requests');
  }

  @override
  String toString() => userMessage;
}

class AIRateLimitedException implements Exception {
  static const userMessage =
      'Nabi đang bận xử lý nhiều yêu cầu. Lịch của bạn đã được lưu tạm; hãy tiếp tục sau.';

  const AIRateLimitedException();

  static bool matches(Object error) {
    if (error is GeminiApiException) {
      final status = error.status?.trim().toLowerCase();
      return error.statusCode == 429 ||
          status == 'resource_exhausted' ||
          status == 'rate_limit_exceeded';
    }
    final text = error.toString().toLowerCase();
    return text.contains('too many requests') ||
        text.contains('rate limit') ||
        text.contains('resource_exhausted');
  }

  @override
  String toString() => userMessage;
}
