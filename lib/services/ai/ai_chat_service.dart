import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'ai_vietnamese_text_validator.dart';

final aiChatServiceProvider = Provider<AIChatService>((ref) {
  return AIChatService();
});

class AIChatService {
  static const _emptyFallback =
      'Xin lỗi, mình chưa hiểu ý bạn. Bạn có thể diễn đạt lại được không?';
  static const _invalidVietnameseFallback =
      'Mình chưa tạo được câu trả lời tiếng Việt rõ ràng. Bạn thử lại giúp mình nhé!';
  static const _technicalFallback =
      'Mình đang gặp chút vấn đề kỹ thuật. Bạn thử lại sau nhé!';

  late final GenerativeModel _model;
  late ChatSession _chatSession;

  AIChatService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    final model = dotenv.env['GEMINI_MODEL'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Không tìm thấy GEMINI_API_KEY');
    }

    _model = GenerativeModel(
      model: model ?? 'gemini-2.5-flash',
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
    try {
      debugPrint('AI CHAT - Sending message: $message');

      final response = await _chatSession.sendMessage(Content.text(message));
      final text = _validatedResponse(response.text);

      debugPrint('AI CHAT - Response: $text');

      return text;
    } catch (e, stackTrace) {
      debugPrint('AI CHAT ERROR: $e');
      debugPrint('Stack trace: $stackTrace');

      return _technicalFallback;
    }
  }

  void resetChat() {
    _chatSession = _model.startChat();
    debugPrint('AI CHAT - Session reset');
  }

  Future<Stream<String>> sendMessageStream(String message) async {
    try {
      debugPrint('AI CHAT STREAM - Sending message: $message');

      final response = _chatSession.sendMessageStream(Content.text(message));
      final text = await response.map((event) => event.text ?? '').join();

      return Stream.value(_validatedResponse(text));
    } catch (e) {
      debugPrint('AI CHAT STREAM ERROR: $e');
      return Stream.value(_technicalFallback);
    }
  }

  static String _validatedResponse(String? rawText) {
    final text = rawText?.trim() ?? '';
    if (text.isEmpty) {
      return _emptyFallback;
    }

    if (!AIVietnameseTextValidator.isValidDisplayText(text)) {
      return _invalidVietnameseFallback;
    }

    return text;
  }
}
