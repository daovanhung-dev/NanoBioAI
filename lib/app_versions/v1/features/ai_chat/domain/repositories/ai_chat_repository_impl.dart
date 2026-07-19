import 'package:nano_app/services/supabase/usage_quota/usage_quota_gateway.dart';

import '../../../../services/ai/ai_chat_service.dart';
import '../../../../services/ai/ai_exceptions.dart';
import '../../data/models/chat_message_model.dart';
import '../entities/chat_message_entity.dart';
import 'ai_chat_repository.dart';

class AIChatRepositoryImpl implements AIChatRepository {
  final AIChatService _aiChatService;
  final UsageQuotaGateway? _quotaGateway;
  final List<ChatMessageEntity> _history = [];
  final Future<void> Function(Duration) _delay;
  final String Function(DateTime) _requestIdFactory;

  AIChatRepositoryImpl({
    required AIChatService aiChatService,
    UsageQuotaGateway? quotaGateway,
    Future<void> Function(Duration)? delay,
    String Function(DateTime)? requestIdFactory,
  }) : _aiChatService = aiChatService,
       _quotaGateway = quotaGateway,
       _delay = delay ?? Future<void>.delayed,
       _requestIdFactory =
           requestIdFactory ??
           ((timestamp) => 'ai-chat-${timestamp.microsecondsSinceEpoch}');

  @override
  Future<ChatMessageEntity> sendMessage(String message) async {
    final timestamp = DateTime.now();
    final requestId = _requestIdFactory(timestamp);

    await _checkQuota(requestId: requestId, at: timestamp);

    // Create user message
    final userMessage = ChatMessageModel(
      id: timestamp.millisecondsSinceEpoch.toString(),
      content: message,
      role: MessageRole.user,
      timestamp: timestamp,
    );

    _history.add(userMessage);

    // Get AI response
    final AIChatPreparedResponse preparedResponse;
    try {
      preparedResponse = await _aiChatService.prepareMessage(message);
    } catch (error, stackTrace) {
      if (error is AIConfigurationUnavailableException ||
          error is AIAuthenticationException ||
          error is AIOverloadedException ||
          error is AIResponseInvalidException) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      Error.throwWithStackTrace(const AIChatUnavailableException(), stackTrace);
    }

    await _commitQuotaWithRetry(requestId: requestId);
    preparedResponse.accept();

    // Create AI message
    final aiMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: preparedResponse.text,
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

  Future<void> _checkQuota({
    required String requestId,
    required DateTime at,
  }) async {
    try {
      await _quotaGateway?.checkCurrentUserQuota(
        featureKey: UsageQuotaFeatureKey.aiChatMessage,
        requestId: requestId,
        at: at,
      );
    } on UsageQuotaException {
      rethrow;
    } catch (_) {
      throw const UsageQuotaUnavailableException();
    }
  }

  Future<void> _commitQuotaWithRetry({required String requestId}) async {
    if (_quotaGateway == null) return;
    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        await _quotaGateway.commitCurrentUserQuota(
          featureKey: UsageQuotaFeatureKey.aiChatMessage,
          requestId: requestId,
          at: DateTime.now(),
        );
        return;
      } on UsageQuotaExceededException {
        rethrow;
      } catch (error) {
        lastError = error;
        if (attempt < 3) {
          await _delay(Duration(milliseconds: attempt == 1 ? 150 : 450));
        }
      }
    }
    if (lastError is UsageQuotaException) throw lastError;
    throw const UsageQuotaUnavailableException();
  }
}
