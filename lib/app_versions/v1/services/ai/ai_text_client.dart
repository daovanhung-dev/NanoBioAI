import 'dart:typed_data';

enum AiMessageRole { user, assistant }

enum AiResponseFormat { text, json }

class AiImageAttachment {
  const AiImageAttachment({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

class AiMessage {
  const AiMessage({
    required this.role,
    required this.text,
    this.images = const [],
  });

  const AiMessage.user(this.text, {this.images = const []})
    : role = AiMessageRole.user;

  const AiMessage.assistant(this.text)
    : role = AiMessageRole.assistant,
      images = const [];

  final AiMessageRole role;
  final String text;
  final List<AiImageAttachment> images;
}

class AiGenerationConfig {
  const AiGenerationConfig({
    this.maxOutputTokens,
    this.temperature,
    this.topP,
    this.responseFormat = AiResponseFormat.text,
    this.responseJsonSchema,
  });

  final int? maxOutputTokens;
  final double? temperature;
  final double? topP;
  final AiResponseFormat responseFormat;
  final Map<String, dynamic>? responseJsonSchema;
}

/// Provider-neutral failure information for local model inference.
class AiInferenceException implements Exception {
  const AiInferenceException({
    required this.message,
    this.status,
    this.statusCode,
    this.backendErrorCode,
  });

  final String message;
  final String? status;
  final int? statusCode;
  final String? backendErrorCode;

  bool get isAuthenticationFailure => false;

  bool get isModelUnavailable =>
      status == 'local_model_not_ready' ||
      status == 'local_model_load_failed' ||
      status == 'model_unavailable';

  bool get isNetworkFailure => status == 'network_error';

  bool get isOutputTruncated =>
      status == 'model_context_limit_exceeded' || status == 'output_truncated';

  bool get isTransient => status == 'runtime_busy' || status == 'runtime_error';

  @override
  String toString() => 'AiInferenceException(${status ?? 'unknown'}): $message';
}

abstract interface class AiTextClient {
  Future<String> generateText({
    required String model,
    required List<AiMessage> messages,
    required AiGenerationConfig generationConfig,
    String? systemInstruction,
  });

  Stream<String> streamText({
    required String model,
    required List<AiMessage> messages,
    required AiGenerationConfig generationConfig,
    String? systemInstruction,
  });
}

/// Optional capability exposed by local clients for prompt budgeting.
abstract interface class AiContextAwareClient {
  Future<int> selectedContextSize();

  Future<int> estimateTokens(String text);
}
