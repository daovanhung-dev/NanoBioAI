import 'dart:async';
import 'dart:convert';

import 'package:nano_app/app_versions/v1/services/ai/ai_text_client.dart';
import 'package:nano_app/core/network/backend_api_client.dart';

/// Sends every in-app AI request to the authenticated NanoBio backend.
class BackendAiTextClient implements AiTextClient {
  static const modelId = 'nanobio-backend-qwen3';

  final BackendApiClient? clientOverride;

  const BackendAiTextClient({this.clientOverride});

  BackendApiClient get _client => clientOverride ?? BackendApiClient.shared;

  @override
  Future<String> generateText({
    required String model,
    required List<AiMessage> messages,
    required AiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async {
    _requireAuthenticated();
    try {
      final imageMessages = messages.where(
        (message) => message.images.isNotEmpty,
      );
      final Object? data;
      if (imageMessages.isNotEmpty) {
        if (imageMessages.length != 1) {
          throw const AiInferenceException(
            status: 'invalid_image_request',
            message: 'Mỗi yêu cầu chỉ gửi được một ảnh.',
          );
        }
        final imageMessage = imageMessages.single;
        if (imageMessage.images.length != 1 ||
            imageMessage.role != AiMessageRole.user) {
          throw const AiInferenceException(
            status: 'invalid_image_request',
            message: 'Ảnh gửi lên chưa đúng định dạng.',
          );
        }
        final image = imageMessage.images.single;
        data = await _client.requestMap(
          'POST',
          '/api/v1/food/scan/analyze',
          body: {
            'image_base64': base64Encode(image.bytes),
            'mime_type': image.mimeType,
            'prompt': _withSystemInstruction(
              imageMessage.text,
              systemInstruction,
            ),
          },
        );
      } else {
        data = await _client.requestMap(
          'POST',
          '/api/v1/ai/generate',
          body: _requestBody(messages, generationConfig, systemInstruction),
        );
      }
      if (data is Map && data['text'] is String) {
        final text = (data['text'] as String).trim();
        if (text.isNotEmpty) return text;
      }
      throw const AiInferenceException(
        status: 'invalid_response',
        message: 'Nabi chưa nhận được câu trả lời phù hợp lúc này.',
      );
    } on BackendApiException catch (error) {
      throw _mapBackendError(error);
    }
  }

  @override
  Stream<String> streamText({
    required String model,
    required List<AiMessage> messages,
    required AiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async* {
    _requireAuthenticated();

    var completed = false;
    try {
      await for (final event in _client.streamEvents(
        'POST',
        '/api/v1/ai/generate/stream',
        body: _requestBody(messages, generationConfig, systemInstruction),
      )) {
        switch (event['type']) {
          case 'delta':
            final data = event['data'];
            final delta = data is Map ? data['text'] : null;
            if (delta is String && delta.isNotEmpty) yield delta;
          case 'complete':
            completed = true;
          case 'error':
            throw _mapStreamError(event);
          default:
            throw const AiInferenceException(
              status: 'invalid_response',
              message: 'Máy chủ trả về phản hồi không hợp lệ.',
            );
        }
      }
    } on BackendApiException catch (error) {
      throw _mapBackendError(error);
    }
    if (!completed) {
      throw const AiInferenceException(
        status: 'invalid_response',
        message: 'Nabi chưa nhận được câu trả lời trọn vẹn.',
      );
    }
  }

  void _requireAuthenticated() {
    if (_client.session != null) return;
    throw const BackendAiInferenceException(
      status: 'authentication_required',
      statusCode: 401,
      backendErrorCode: 'AUTHENTICATION_REQUIRED',
      message: 'Đăng nhập để sử dụng các tính năng AI của NanoBio.',
    );
  }

  Map<String, Object?> _requestBody(
    List<AiMessage> messages,
    AiGenerationConfig config,
    String? systemInstruction,
  ) => {
    'messages': [
      for (final message in messages)
        {
          'role': message.role == AiMessageRole.user ? 'user' : 'assistant',
          'content': message.text,
        },
    ],
    if (systemInstruction != null && systemInstruction.trim().isNotEmpty)
      'system_instruction': systemInstruction.trim(),
    'response_format': config.responseFormat == AiResponseFormat.json
        ? 'json'
        : 'text',
    if (config.responseJsonSchema != null)
      'json_schema': config.responseJsonSchema,
    if (config.maxOutputTokens != null)
      'max_output_tokens': config.maxOutputTokens,
    if (config.temperature != null) 'temperature': config.temperature,
    if (config.topP != null) 'top_p': config.topP,
  };

  String _withSystemInstruction(String prompt, String? instruction) {
    final prefix = instruction?.trim();
    if (prefix == null || prefix.isEmpty) return prompt;
    return '$prefix\n\n$prompt';
  }

  AiInferenceException _mapStreamError(Map<String, Object?> event) {
    final code = event['businessCode']?.toString() ?? 'AI_PROVIDER_FAILURE';
    final message =
        event['message']?.toString() ?? 'Nabi chưa thể trả lời lúc này.';
    return _mapError(code, message);
  }

  BackendAiInferenceException _mapBackendError(BackendApiException error) =>
      _mapError(
        error.businessCode,
        error.message,
        statusCode: error.statusCode,
      );

  BackendAiInferenceException _mapError(
    String code,
    String message, {
    int? statusCode,
  }) {
    final status = switch (code) {
      'NETWORK_UNAVAILABLE' => 'network_error',
      'AI_TIMEOUT' => 'runtime_error',
      'AI_UNAVAILABLE' || 'FEATURE_NOT_ENABLED' => 'model_unavailable',
      'MODEL_CONTEXT_LIMIT_EXCEEDED' => 'model_context_limit_exceeded',
      'AI_RESPONSE_TRUNCATED' => 'output_truncated',
      'RATE_LIMITED' => 'rate_limit_exceeded',
      'MEMBERSHIP_REQUIRED' => 'membership_required',
      _ => 'backend_error',
    };
    return BackendAiInferenceException(
      status: status,
      statusCode: statusCode,
      backendErrorCode: code,
      message: message,
    );
  }
}

class BackendAiInferenceException extends AiInferenceException {
  const BackendAiInferenceException({
    required super.message,
    super.status,
    super.statusCode,
    super.backendErrorCode,
  });

  @override
  bool get isAuthenticationFailure =>
      statusCode == 401 ||
      backendErrorCode == 'AUTHENTICATION_REQUIRED' ||
      backendErrorCode == 'LOGIN_REQUIRED';
}
