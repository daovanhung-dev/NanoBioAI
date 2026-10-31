import 'dart:async';

import 'ai_text_client.dart';

class AIConfigurationUnavailableException implements Exception {
  static const userMessage =
      'Dịch vụ AI của NanoBio chưa được cấu hình. Bạn thử lại sau nhé.';

  const AIConfigurationUnavailableException();

  @override
  String toString() => userMessage;
}

class AIInferenceTimeoutException implements Exception {
  static const userMessage =
      'Nabi cần thêm thời gian để trả lời. Bạn thử gửi lại nhé.';

  const AIInferenceTimeoutException();

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
      'Đăng nhập vào NanoBio để sử dụng các tính năng AI.';

  const AIAuthenticationException();

  static bool matches(Object error) {
    return error is AIAuthenticationException ||
        error is AiInferenceException && error.isAuthenticationFailure;
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
    return error is AiInferenceException && error.isNetworkFailure;
  }

  @override
  String toString() => userMessage;
}

class AIModelUnavailableException implements Exception {
  static const userMessage =
      'Nabi hiện chưa sẵn sàng. Bạn thử lại sau một chút nhé.';

  const AIModelUnavailableException();

  static bool matches(Object error) {
    return error is AiInferenceException && error.isModelUnavailable;
  }

  @override
  String toString() => userMessage;
}

class AIModelContextLimitException implements Exception {
  static const userMessage =
      'Nội dung vượt quá giới hạn model đã chọn. Hãy rút gọn dữ liệu hoặc chọn model có context lớn hơn.';

  const AIModelContextLimitException();

  static bool matches(Object error) {
    return error is AiInferenceException &&
        error.status?.trim().toLowerCase() == 'model_context_limit_exceeded';
  }

  @override
  String toString() => userMessage;
}

class AIRequestTooLargeException implements Exception {
  static const userMessage =
      'Danh sách dữ liệu vượt quá giới hạn xử lý của model đã chọn.';

  const AIRequestTooLargeException();

  static bool matches(Object error) {
    return error is AiInferenceException &&
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

    if (error is AiInferenceException) {
      final status = error.status?.trim().toLowerCase();
      final code = error.backendErrorCode?.trim().toUpperCase();
      return error.isTransient ||
          error.statusCode == 408 ||
          error.statusCode == 429 ||
          status == 'rate_limit_exceeded' ||
          status == 'resource_exhausted' ||
          code == 'RATE_LIMITED';
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
    if (error is AiInferenceException) {
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

class AIPlatformUnsupportedException implements Exception {
  static const userMessage =
      'Dịch vụ AI của NanoBio chưa được bật trên nền tảng này. Bạn thử lại sau nhé.';

  const AIPlatformUnsupportedException();

  static bool matches(Object error) =>
      error is AiInferenceException && error.status == 'unsupported_platform';

  @override
  String toString() => userMessage;
}
