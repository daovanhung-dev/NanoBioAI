import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

final aiChatServiceProvider = Provider<AIChatService>((ref) {
  return AIChatService();
});

class AIChatService {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  AIChatService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    final model = dotenv.env['GEMINI_MODEL'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Không tìm thấy GEMINI_API_KEY');
    }

    _model = GenerativeModel(
      model: model ?? 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system('''
Bạn là BioAI Assistant - trợ lý sức khỏe AI thông minh và thân thiện.

Vai trò:
- Tư vấn về dinh dưỡng, giấc ngủ, stress, và lối sống lành mạnh
- Đưa ra gợi ý cá nhân hóa dựa trên thông tin sức khỏe người dùng
- Luôn lắng nghe và thấu hiểu

Phong cách:
- Gọi người dùng là "bạn", tự xưng là "mình"
- Thân thiện, ấm áp nhưng chuyên nghiệp
- Câu trả lời ngắn gọn, dễ hiểu (2-4 câu)
- Tránh dùng thuật ngữ y khoa phức tạp
- Luôn khuyến khích và tích cực

Nguyên tắc:
- KHÔNG đưa ra chẩn đoán y tế
- KHÔNG thay thế bác sĩ
- Khuyến khích gặp bác sĩ nếu vấn đề nghiêm trọng
- Tập trung vào thói quen sinh hoạt và dinh dưỡng

Ví dụ trả lời tốt:
"Mình hiểu bạn đang cảm thấy mệt mỏi. Theo mình, bạn nên ưu tiên ngủ đủ 7-8 tiếng mỗi đêm. Uống đủ nước và ăn nhiều rau xanh cũng giúp ích rất nhiều đấy! Bạn thử áp dụng xem sao nhé."
'''),
    );

    _chatSession = _model.startChat();
  }

  Future<String> sendMessage(String message) async {
    try {
      debugPrint('AI CHAT - Sending message: $message');

      final response = await _chatSession.sendMessage(
        Content.text(message),
      );

      final text = response.text;

      if (text == null || text.trim().isEmpty) {
        return 'Xin lỗi, mình chưa hiểu ý bạn. Bạn có thể diễn đạt lại được không?';
      }

      debugPrint('AI CHAT - Response: $text');

      return text.trim();
    } catch (e, stackTrace) {
      debugPrint('AI CHAT ERROR: $e');
      debugPrint('Stack trace: $stackTrace');

      return 'Mình đang gặp chút vấn đề kỹ thuật. Bạn thử lại sau nhé!';
    }
  }

  void resetChat() {
    _chatSession = _model.startChat();
    debugPrint('AI CHAT - Session reset');
  }

  Future<Stream<String>> sendMessageStream(String message) async {
    try {
      debugPrint('AI CHAT STREAM - Sending message: $message');

      final response = _chatSession.sendMessageStream(
        Content.text(message),
      );

      return response.map((event) => event.text ?? '');
    } catch (e) {
      debugPrint('AI CHAT STREAM ERROR: $e');
      return Stream.value(
        'Mình đang gặp chút vấn đề kỹ thuật. Bạn thử lại sau nhé!',
      );
    }
  }
}
