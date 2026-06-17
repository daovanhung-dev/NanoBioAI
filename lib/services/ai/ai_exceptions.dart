import 'dart:async';

import 'package:google_generative_ai/google_generative_ai.dart';

class AIOverloadedException implements Exception {
  static const userMessage = 'AI bị quá tải. Bạn thử lại sau nhé.';

  const AIOverloadedException();

  static bool matches(Object error) {
    if (error is TimeoutException) {
      return true;
    }

    final message = error is GenerativeAIException
        ? error.message
        : error.toString();
    final normalized = message.toLowerCase();

    return normalized.contains('overload') ||
        normalized.contains('server error [503]') ||
        normalized.contains('server error [429]') ||
        normalized.contains('unavailable') ||
        normalized.contains('resource_exhausted') ||
        normalized.contains('resource has been exhausted') ||
        normalized.contains('quota') ||
        normalized.contains('rate limit') ||
        normalized.contains('too many requests');
  }

  @override
  String toString() => userMessage;
}
