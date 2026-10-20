import 'dart:async';

import 'package:nano_app/app_versions/v1/services/ai/ai_text_client.dart';
import 'package:nano_app/core/ai_local/local_ai_text_client.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_text_sanitizer.dart';

import '../../domain/entities/voice_chat_message.dart';
import '../../domain/voice_chat_exception.dart';

abstract class VoiceChatTurnDatasource {
  Future<String> sendTurn({
    required String message,
    required List<VoiceChatMessage> history,
  });
}

class LocalVoiceChatTurnDatasource implements VoiceChatTurnDatasource {
  static const defaultModel = LocalAiTextClient.modelId;
  static const maxInputCharacters = 6000;
  static const maxHistoryMessageCharacters = 6000;
  static const maxResponseCharacters = 2000;
  static const maxHistoryMessages = 12;
  static const defaultRequestTimeout = Duration(seconds: 60);

  static const systemInstruction = '''
Bạn là Nabi, trợ lý sức khỏe AI thân thiện của NanoBio.
Luôn trả lời bằng tiếng Việt, ngắn gọn, rõ ràng và phù hợp để đọc thành tiếng.
- Không dùng markdown hoặc ký tự trang trí đặc biệt.
Không chẩn đoán, kê đơn hoặc tự nhận thay thế bác sĩ.
Nếu người dùng mô tả dấu hiệu nguy hiểm tức thời hoặc tình huống cấp cứu,
hãy khuyên họ gọi 115 tại Việt Nam hoặc đến cơ sở cấp cứu gần nhất.
''';

  LocalVoiceChatTurnDatasource({
    AiTextClient? client,
    this.requestTimeout = defaultRequestTimeout,
  }) : _client = client ?? const LocalAiTextClient(operation: 'voice_chat');

  final AiTextClient _client;
  final Duration requestTimeout;

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
      final response = await _client
          .generateText(
            model: defaultModel,
            messages: [
              for (final item in history)
                switch (item.role) {
                  VoiceChatRole.user => AiMessage.user(item.text.trim()),
                  VoiceChatRole.model => AiMessage.assistant(item.text.trim()),
                },
              AiMessage.user(normalizedMessage),
            ],
            generationConfig: const AiGenerationConfig(temperature: 0.2),
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
    } on AiInferenceException catch (error) {
      if (error.status == 'unsupported_platform') {
        throw const VoiceChatException(VoiceChatFailure.unsupportedPlatform);
      }
      if (error.isTransient || error.isNetworkFailure) {
        throw const VoiceChatException(VoiceChatFailure.temporarilyUnavailable);
      }
      throw const VoiceChatException(VoiceChatFailure.unavailable);
    } catch (_) {
      throw const VoiceChatException(VoiceChatFailure.unavailable);
    }
  }

  bool _isBoundedText(String value, int maxCharacters) =>
      value.isNotEmpty && value.runes.length <= maxCharacters;
}
