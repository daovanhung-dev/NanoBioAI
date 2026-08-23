import 'dart:async';

import 'package:nano_app/app_versions/v1/services/ai/gemini_rest_client.dart';
import 'package:nano_app/core/config/app_env.dart';

import '../../domain/entities/voice_chat_message.dart';
import '../../domain/voice_chat_exception.dart';

typedef VoiceEnvironmentReader = String? Function(String key);

abstract class VoiceChatTurnDatasource {
  Future<String> sendTurn({
    required String message,
    required List<VoiceChatMessage> history,
  });
}

/// Calls Gemini directly from the app for one sequential Voice turn.
///
/// Paid access remains enforced by the page gate. Conversation content stays
/// in the in-memory repository and is never persisted by this datasource.
class GeminiVoiceChatTurnDatasource implements VoiceChatTurnDatasource {
  static const defaultModel = 'gemini-3.5-flash';
  static const maxInputCharacters = 6000;
  static const maxHistoryMessageCharacters = 6000;
  static const maxResponseCharacters = 2000;
  static const maxHistoryMessages = 12;
  static const maxOutputTokens = 256;
  static const defaultRequestTimeout = Duration(seconds: 30);

  static const systemInstruction = '''
Bạn là Nabi, trợ lý sức khỏe AI thân thiện của NanoBio.
Luôn trả lời bằng tiếng Việt, ngắn gọn, rõ ràng và phù hợp để đọc thành tiếng.
Không chẩn đoán, kê đơn hoặc tự nhận thay thế bác sĩ.
Nếu người dùng mô tả dấu hiệu nguy hiểm tức thời hoặc tình huống cấp cứu,
hãy khuyên họ gọi 115 tại Việt Nam hoặc đến cơ sở cấp cứu gần nhất.
''';

  final GeminiRestClient? clientOverride;
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
              maxOutputTokens: maxOutputTokens,
              thinkingLevel: 'MINIMAL',
            ),
            systemInstruction: systemInstruction,
          )
          .timeout(requestTimeout);
      final normalizedResponse = response.trim();
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

  GeminiRestClient _client() {
    final override = clientOverride;
    if (override != null) return override;

    final apiKey = _readEnvironment('GEMINI_API_KEY')?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw const VoiceChatException(VoiceChatFailure.unavailable);
    }
    return GeminiRestClient(
      apiKey: apiKey,
      baseUrl: _readEnvironment('GEMINI_BASE_URL'),
      post: _postOverride,
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
