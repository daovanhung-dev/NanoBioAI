import 'dart:async';

import 'gemini_rest_client.dart';

class AIConfigurationUnavailableException implements Exception {
  const AIConfigurationUnavailableException();

  @override
  String toString() => 'AI runtime configuration is unavailable.';
}

class AIResponseInvalidException implements Exception {
  const AIResponseInvalidException();

  @override
  String toString() => 'AI response is unavailable or invalid.';
}

class AIAuthenticationException implements Exception {
  static const userMessage =
      'Khóa AI hiện tại chưa được Gemini chấp nhận. Bạn hãy tạo một Gemini API key hợp lệ rồi cập nhật cấu hình và mở lại ứng dụng nhé.';

  const AIAuthenticationException();

  static bool matches(Object error) {
    if (error is! GeminiApiException) {
      return false;
    }

    final status = error.status?.toLowerCase();
    return error.statusCode == 401 ||
        error.statusCode == 403 ||
        status == 'unauthenticated' ||
        status == 'permission_denied';
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
