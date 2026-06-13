import '../entities/chat_message_entity.dart';

abstract class AIChatRepository {
  Future<ChatMessageEntity> sendMessage(String message);
  
  Future<List<ChatMessageEntity>> getChatHistory();
  
  Future<void> clearHistory();
}
