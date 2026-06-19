import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'ai_trace_logger.dart';
import 'ai_vietnamese_text_validator.dart';

final aiChatServiceProvider = Provider<AIChatService>((ref) {
  return AIChatService();
});

class AIChatService {
  static const _tag = 'AI_CHAT';
  static const _emptyFallback =
      'Xin lỗi, mình chưa hiểu ý bạn. Bạn có thể diễn đạt lại được không?';
  static const _invalidVietnameseFallback =
      'Mình chưa tạo được câu trả lời tiếng Việt rõ ràng. Bạn thử lại giúp mình nhé!';
  static const _technicalFallback =
      'Mình đang gặp chút vấn đề kỹ thuật. Bạn thử lại sau nhé!';

  late final String _modelName;
  late final GenerativeModel _model;
  late ChatSession _chatSession;

  AIChatService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    final model = dotenv.env['GEMINI_MODEL'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Không tìm thấy GEMINI_API_KEY');
    }

    _modelName = model ?? 'gemini-3.5-flash';
    AITraceLogger.info(
      _tag,
      AITraceLogger.nextTraceId('ai-chat-init'),
      'AIChatService.constructor',
      'MODEL_RESOLVED',
      'Resolved chat model name',
      data: {'model': _modelName},
      location: StackTrace.current,
    );

    _model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        candidateCount: 1,
        maxOutputTokens: 512,
        temperature: 0.4,
        topP: 0.8,
      ),
      systemInstruction: Content.system('''
Bạn là BioAI Assistant, trợ lý sức khỏe thông minh và thân thiện.

Vai trò:
- Tư vấn về dinh dưỡng, giấc ngủ, căng thẳng và lối sống lành mạnh.
- Đưa ra gợi ý cá nhân hóa dựa trên thông tin sức khỏe người dùng.
- Luôn lắng nghe, thấu hiểu và trả lời thực tế.

Phong cách:
- Luôn trả lời bằng tiếng Việt có dấu.
- Gọi người dùng là "bạn", tự xưng là "mình".
- Câu trả lời ngắn gọn, dễ hiểu, thường từ 2 đến 4 câu.
- Tránh thuật ngữ y khoa phức tạp khi không cần thiết.
- Có giọng thân thiện, ấm áp và chuyên nghiệp.

Nguyên tắc an toàn:
- Không đưa ra chẩn đoán y tế.
- Không thay thế bác sĩ hoặc chuyên gia điều trị.
- Khuyến khích gặp bác sĩ khi triệu chứng nghiêm trọng, kéo dài hoặc bất thường.
- Tập trung vào thói quen sinh hoạt, dinh dưỡng, vận động và nghỉ ngơi.
- Chỉ dùng token kỹ thuật phổ biến khi thật cần thiết, ví dụ AI, BMI, kcal hoặc ml.

Ví dụ phong cách:
"Mình hiểu bạn đang cảm thấy mệt. Bạn nên ưu tiên ngủ đủ 7 đến 8 tiếng mỗi đêm, uống đủ nước và ăn thêm rau xanh. Nếu tình trạng kéo dài hoặc nặng hơn, bạn nên trao đổi với bác sĩ nhé."
'''),
    );

    _chatSession = _model.startChat();
  }

  Future<String> sendMessage(String message) async {
    final traceId = AITraceLogger.nextTraceId('ai-chat-message');
    const method = 'sendMessage';
    AITraceLogger.start(
      _tag,
      traceId,
      method,
      data: {'model': _modelName, 'message': message},
      location: StackTrace.current,
    );

    try {
      final response = await _chatSession.sendMessage(Content.text(message));
      AITraceLogger.payload(
        _tag,
        traceId,
        method,
        'RAW_RESPONSE',
        response.text,
        location: StackTrace.current,
      );

      final validation = _validatedResponse(response.text);
      AITraceLogger.payload(
        _tag,
        traceId,
        method,
        'VALIDATED_RESPONSE',
        validation.toMap(),
        location: StackTrace.current,
      );

      if (validation.source == AITraceLogger.aiGen) {
        AITraceLogger.success(
          _tag,
          traceId,
          method,
          'SUCCESS',
          'AI chat trả lời thành công.',
          data: {'source': validation.source},
          location: StackTrace.current,
        );
      } else {
        AITraceLogger.warning(
          _tag,
          traceId,
          method,
          'LOCAL_FALLBACK',
          'AI chat dùng câu trả lời fallback local.',
          data: validation.toMap(),
          location: StackTrace.current,
        );
      }

      return validation.text;
    } catch (e, stackTrace) {
      AITraceLogger.error(
        _tag,
        traceId,
        method,
        'ERROR_LOCAL_FALLBACK',
        'AI chat lỗi và chuyển sang fallback local.',
        e,
        stackTrace,
        data: {
          'source': AITraceLogger.localGen,
          'fallback': _technicalFallback,
        },
        location: StackTrace.current,
      );
      return _technicalFallback;
    }
  }

  void resetChat() {
    final traceId = AITraceLogger.nextTraceId('ai-chat-reset');
    const method = 'resetChat';
    _chatSession = _model.startChat();
    AITraceLogger.info(
      _tag,
      traceId,
      method,
      'SESSION_RESET',
      'AI chat session reset.',
      data: {'model': _modelName},
      location: StackTrace.current,
    );
  }

  Future<Stream<String>> sendMessageStream(String message) async {
    final traceId = AITraceLogger.nextTraceId('ai-chat-stream');
    const method = 'sendMessageStream';
    AITraceLogger.start(
      _tag,
      traceId,
      method,
      data: {'model': _modelName, 'message': message},
      location: StackTrace.current,
    );

    try {
      final response = _chatSession.sendMessageStream(Content.text(message));
      final text = await response.map((event) => event.text ?? '').join();
      AITraceLogger.payload(
        _tag,
        traceId,
        method,
        'RAW_STREAM_RESPONSE',
        text,
        location: StackTrace.current,
      );

      final validation = _validatedResponse(text);
      AITraceLogger.payload(
        _tag,
        traceId,
        method,
        'VALIDATED_STREAM_RESPONSE',
        validation.toMap(),
        location: StackTrace.current,
      );

      if (validation.source == AITraceLogger.aiGen) {
        AITraceLogger.success(
          _tag,
          traceId,
          method,
          'SUCCESS',
          'AI chat stream trả lời thành công.',
          data: {'source': validation.source},
          location: StackTrace.current,
        );
      } else {
        AITraceLogger.warning(
          _tag,
          traceId,
          method,
          'LOCAL_FALLBACK',
          'AI chat stream dùng câu trả lời fallback local.',
          data: validation.toMap(),
          location: StackTrace.current,
        );
      }

      return Stream.value(validation.text);
    } catch (e, stackTrace) {
      AITraceLogger.error(
        _tag,
        traceId,
        method,
        'ERROR_LOCAL_FALLBACK',
        'AI chat stream lỗi và chuyển sang fallback local.',
        e,
        stackTrace,
        data: {
          'source': AITraceLogger.localGen,
          'fallback': _technicalFallback,
        },
        location: StackTrace.current,
      );
      return Stream.value(_technicalFallback);
    }
  }

  static _AIChatValidationResult _validatedResponse(String? rawText) {
    final text = rawText?.trim() ?? '';
    if (text.isEmpty) {
      return const _AIChatValidationResult(
        text: _emptyFallback,
        source: AITraceLogger.localGen,
        reason: 'empty_response',
      );
    }

    if (!AIVietnameseTextValidator.isValidDisplayText(text)) {
      return const _AIChatValidationResult(
        text: _invalidVietnameseFallback,
        source: AITraceLogger.localGen,
        reason: 'invalid_vietnamese_response',
      );
    }

    return _AIChatValidationResult(
      text: text,
      source: AITraceLogger.aiGen,
      reason: 'valid_ai_response',
    );
  }
}

class _AIChatValidationResult {
  final String text;
  final String source;
  final String reason;

  const _AIChatValidationResult({
    required this.text,
    required this.source,
    required this.reason,
  });

  Map<String, Object?> toMap() {
    return {'text': text, 'source': source, 'reason': reason};
  }
}
