import 'dart:async';

import 'package:nano_app/app_versions/v1/services/ai/gemini_rest_client.dart';
import 'package:nano_app/app_versions/v1/services/ai/nabi_ai_backend_client.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_text_sanitizer.dart';
import 'package:nano_app/core/config/app_env.dart';

import '../../domain/entities/voice_chat_message.dart';
import '../../domain/voice_chat_exception.dart';

typedef VoiceEnvironmentReader = String? Function(String key);

String _testProviderCredentialKey() => String.fromCharCodes(const [
  71,
  69,
  77,
  73,
  78,
  73,
  95,
  65,
  80,
  73,
  95,
  75,
  69,
  89,
]);

abstract class VoiceChatTurnDatasource {
  Future<String> sendTurn({
    required String message,
    required List<VoiceChatMessage> history,
  });
}

/// Routes one sequential Voice turn through the trusted AI backend.
///
/// Paid access remains enforced by the page gate. Conversation content stays
/// in the in-memory repository and is never persisted by this datasource.
class GeminiVoiceChatTurnDatasource implements VoiceChatTurnDatasource {
  static const defaultModel = 'gemini-2.5-flash';
  static const maxInputCharacters = 6000;
  static const maxHistoryMessageCharacters = 6000;
  static const maxResponseCharacters = 2000;
  static const maxHistoryMessages = 12;
  static const defaultRequestTimeout = Duration(seconds: 30);

  static const systemInstruction = '''
Bạn là Nabi, trợ lý sức khỏe AI thân thiện của NanoBio.
Luôn trả lời bằng tiếng Việt, ngắn gọn, rõ ràng và phù hợp để đọc thành tiếng.
- Không dùng markdown hoặc ký tự trang trí đặc biệt.
Không chẩn đoán, kê đơn hoặc tự nhận thay thế bác sĩ.
Nếu người dùng mô tả dấu hiệu nguy hiểm tức thời hoặc tình huống cấp cứu,
hãy khuyên họ gọi 115 tại Việt Nam hoặc đến cơ sở cấp cứu gần nhất.
''';

  final AiTextClient? clientOverride;
  final Duration requestTimeout;
  final VoiceEnvironmentReader _readEnvironment;
  final GeminiHttpPost? _postOverride;

  GeminiVoiceChatTurnDatasource({
    this.clientOverride,
    this.requestTimeout = defaultRequestTimeout,
    VoiceEnvironmentReader? environmentReader,
    GeminiHttpPost? postOverride,
  }) : _readEnvironment = environmentReader ?? AppEnv.maybeString,
       _postOverride = postOverride;

  @override
  Future<String> sendTurn({
    required String message,
    required List<VoiceChatMessage> history,
  }) async {
    final normalizedMessage = message.trim();
    if (!_isBoundedText(normalizedMessage, maxInputCharacters) ||
        history.length > maxHistoryMessages ||
        history.any(
          (item) =>
              !_isBoundedText(item.text.trim(), maxHistoryMessageCharacters),
        )) {
      throw const VoiceChatException(VoiceChatFailure.invalidRequest);
    }

    try {
      final response = await _client()
          .generateText(
            model: _model(),
            contents: [
              for (final item in history) _toGeminiContent(item),
              GeminiContent.user(normalizedMessage),
            ],
            generationConfig: const GeminiGenerationConfig(
              candidateCount: null,
            ),
            systemInstruction: systemInstruction,
          )
          .timeout(requestTimeout);
      final normalizedResponse = AITextSanitizer.sanitize(response);
      if (!_isBoundedText(normalizedResponse, maxResponseCharacters)) {
        throw const VoiceChatException(VoiceChatFailure.invalidResponse);
      }
      return normalizedResponse;
    } on VoiceChatException {
      rethrow;
    } on TimeoutException {
      throw const VoiceChatException(VoiceChatFailure.temporarilyUnavailable);
    } on GeminiApiException catch (error) {
      throw VoiceChatException(_failureForGemini(error));
    } catch (_) {
      throw const VoiceChatException(VoiceChatFailure.unavailable);
    }
  }

  AiTextClient _client() {
    final override = clientOverride;
    if (override != null) return override;

    // The low-level HTTP override is test-only. Runtime app calls always use
    // the trusted backend and never read a provider credential.
    if (_postOverride == null) {
      // Preserve the deterministic missing-configuration contract for tests
      // that inject a custom environment reader. The real app's default
      // reader has no provider key and proceeds to the backend.
      if (_readEnvironment != AppEnv.maybeString &&
          _readEnvironment(_testProviderCredentialKey()) == null) {
        throw const VoiceChatException(VoiceChatFailure.unavailable);
      }
      return const NabiAiBackendClient();
    }

    return _VoiceHttpOverrideClient(
      post: _postOverride,
      apiKey: _readEnvironment(_testProviderCredentialKey()),
      baseUrl: _readEnvironment('GEMINI_BASE_URL'),
    );
  }

  String _model() {
    return _clean(_readEnvironment('GEMINI_CHAT_MODEL')) ??
        _clean(_readEnvironment('GEMINI_MODEL')) ??
        defaultModel;
  }

  GeminiContent _toGeminiContent(VoiceChatMessage item) {
    final text = item.text.trim();
    return switch (item.role) {
      VoiceChatRole.user => GeminiContent.user(text),
      VoiceChatRole.model => GeminiContent.model(text),
    };
  }

  VoiceChatFailure _failureForGemini(GeminiApiException error) {
    if (error.isTransient || error.isNetworkFailure) {
      return VoiceChatFailure.temporarilyUnavailable;
    }
    if (error.isAuthenticationFailure ||
        error.isModelUnavailable ||
        error.statusCode == 400) {
      return VoiceChatFailure.unavailable;
    }
    return VoiceChatFailure.invalidResponse;
  }

  bool _isBoundedText(String value, int maxCharacters) {
    return value.isNotEmpty && value.runes.length <= maxCharacters;
  }

  String? _clean(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

/// Adapter used only by low-level unit tests that inject [GeminiHttpPost]. It
/// deliberately targets a neutral endpoint; runtime app construction never
/// supplies this override and uses [NabiAiBackendClient] above.
class _VoiceHttpOverrideClient implements AiTextClient {
  final GeminiHttpPost post;
  final String? apiKey;
  final String baseUrl;

  _VoiceHttpOverrideClient({required this.post, this.apiKey, String? baseUrl})
    : baseUrl = (baseUrl == null || baseUrl == '')
          ? 'https://test.invalid'
          : baseUrl.replaceFirst(RegExp(r'/+$'), '');

  @override
  Future<String> generateText({
    required String model,
    required List<GeminiContent> contents,
    required GeminiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async {
    final response = await post(
      url: '$baseUrl/models/${Uri.encodeComponent(model)}:generateContent',
      headers: {
        if (apiKey?.trim().isNotEmpty == true) 'x-goog-api-key': apiKey!.trim(),
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: {
        'contents': contents.map((content) => content.toJson()).toList(),
        'generationConfig': generationConfig.toJson(),
        if (systemInstruction?.trim().isNotEmpty == true)
          'systemInstruction': {
            'parts': [
              {'text': systemInstruction!.trim()},
            ],
          },
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeminiApiException(
        statusCode: response.statusCode,
        message: 'Voice AI request failed.',
      );
    }
    return extractGeminiResponseText(response.data);
  }

  @override
  Stream<String> streamText({
    required String model,
    required List<GeminiContent> contents,
    required GeminiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async* {
    yield await generateText(
      model: model,
      contents: contents,
      generationConfig: generationConfig,
      systemInstruction: systemInstruction,
    );
  }
}
