import '../../data/models/chat_message_model.dart';
import '../entities/chat_message_entity.dart';
import 'ai_chat_repository.dart';
import '../../../../services/ai/ai_chat_service.dart';

class AIChatRepositoryImpl implements AIChatRepository {
  final AIChatService _aiChatService;
  final List<ChatMessageEntity> _history = [];

  AIChatRepositoryImpl({required AIChatService aiChatService})
    : _aiChatService = aiChatService;

  @override
  Future<ChatMessageEntity> sendMessage(String message) async {
    final timestamp = DateTime.now();

    // Create user message
    final userMessage = ChatMessageModel(
      id: timestamp.millisecondsSinceEpoch.toString(),
      content: message,
      role: MessageRole.user,
      timestamp: timestamp,
    );

    _history.add(userMessage);

    // Get AI response
    final responseText = await _aiChatService.sendMessage(message);

    // Create AI message
    final aiMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: responseText,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    );

    _history.add(aiMessage);

    return aiMessage;
  }

  @override
  Future<List<ChatMessageEntity>> getChatHistory() async {
    return List.from(_history);
  }

  @override
  Future<void> clearHistory() async {
    _history.clear();
    _aiChatService.resetChat();
  }
}
