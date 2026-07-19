import 'dart:async';

import 'gemini_rest_client.dart';

class AIConfigurationUnavailableException implements Exception {
  static const userMessage =
      'Nabi chưa sẵn sàng trò chuyện AI lúc này. Bạn thử lại sau một chút nhé.';

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
      'Khóa AI chưa hợp lệ. Cập nhật cấu hình rồi mở lại ứng dụng.';

  const AIAuthenticationException();

  static bool matches(Object error) {
    return error is GeminiApiException && error.isAuthenticationFailure;
  }

  @override
  String toString() => userMessage;
}

class AINetworkException implements Exception {
  static const userMessage =
      'Không thể kết nối với AI. Bạn kiểm tra mạng rồi thử lại nhé.';

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
      'Mô hình AI hiện chưa khả dụng. Bạn thử lại sau một chút nhé.';

  const AIModelUnavailableException();

  static bool matches(Object error) {
    return error is GeminiApiException && error.isModelUnavailable;
  }

  @override
  String toString() => userMessage;
}

class AIOverloadedException implements Exception {
  static const userMessage = 'AI đang quá tải. Bạn thử lại sau nhé.';

  const AIOverloadedException();

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
