import 'package:nano_app/services/supabase/usage_quota/usage_quota_gateway.dart';

import '../../../../services/ai/ai_chat_service.dart';
import '../../data/models/chat_message_model.dart';
import '../entities/chat_message_entity.dart';
import 'ai_chat_repository.dart';

class AIChatRepositoryImpl implements AIChatRepository {
  final AIChatService _aiChatService;
  final UsageQuotaGateway? _quotaGateway;
  final List<ChatMessageEntity> _history = [];

  AIChatRepositoryImpl({
    required AIChatService aiChatService,
    UsageQuotaGateway? quotaGateway,
  }) : _aiChatService = aiChatService,
       _quotaGateway = quotaGateway;

  @override
  Future<ChatMessageEntity> sendMessage(String message) async {
    final timestamp = DateTime.now();
    final requestId = 'ai-chat-${timestamp.microsecondsSinceEpoch}';

    await _quotaGateway?.checkCurrentUserQuota(
      featureKey: UsageQuotaFeatureKey.aiChatMessage,
      requestId: requestId,
      at: timestamp,
    );

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

    await _quotaGateway?.commitCurrentUserQuota(
      featureKey: UsageQuotaFeatureKey.aiChatMessage,
      requestId: requestId,
      at: DateTime.now(),
    );

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
