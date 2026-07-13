import '../entities/chat_message_entity.dart';

class AIChatUnavailableException implements Exception {
  static const message =
      'Nabi chưa thể kết nối với trợ lý AI lúc này. Bạn thử lại sau một chút nhé.';

  const AIChatUnavailableException();

  String get userMessage => message;

  @override
  String toString() => userMessage;
}

abstract class AIChatRepository {
  Future<ChatMessageEntity> sendMessage(String message);

  Future<List<ChatMessageEntity>> getChatHistory();

  Future<void> clearHistory();
}
