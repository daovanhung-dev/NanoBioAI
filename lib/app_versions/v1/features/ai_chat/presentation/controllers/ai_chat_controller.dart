import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/nabi/providers/nabi_provider.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_exceptions.dart';
import 'package:nano_app/services/supabase/usage_quota/usage_quota_gateway.dart';

import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../../providers/ai_chat_providers.dart';

class AIChatState {
  final List<ChatMessageEntity> messages;
  final bool isLoading;
  final String? error;
  final bool canRetry;

  const AIChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.canRetry = false,
  });

  AIChatState copyWith({
    List<ChatMessageEntity>? messages,
    bool? isLoading,
    String? error,
    bool? canRetry,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      canRetry: canRetry ?? this.canRetry,
    );
  }
}

class AIChatController extends Notifier<AIChatState> {
  String? _failedMessage;

  @override
  AIChatState build() {
    _loadHistory();
    return const AIChatState();
  }

  AIChatRepository get _repository => ref.read(aiChatRepositoryProvider);

  Future<void> _loadHistory() async {
    try {
      final history = await _repository.getChatHistory();
      state = state.copyWith(messages: history);
    } catch (e) {
      state = state.copyWith(
        error: 'Không thể tải lịch sử trò chuyện',
        canRetry: false,
      );
    }
  }

  Future<void> sendMessage(String message) async {
    if (state.isLoading || message.trim().isEmpty) return;

    final trimmed = message.trim();
    _failedMessage = null;

    final userMessage = ChatMessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: trimmed,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
      canRetry: false,
    );
    ref.read(nabiContextProvider.notifier).setChatTyping(typing: true);

    try {
      final aiMessage = await _repository.sendMessage(trimmed);

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        canRetry: false,
      );
      ref.read(nabiContextProvider.notifier).setChatAnswerReady();
    } catch (e) {
      _failedMessage = trimmed;
      state = state.copyWith(
        isLoading: false,
        error: _messageForSendError(e),
        canRetry: true,
      );
      ref.read(nabiContextProvider.notifier).setChatFailed();
    }
  }

  Future<void> retryLastMessage() async {
    final message = _failedMessage;
    if (state.isLoading || message == null || message.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null, canRetry: false);
    ref.read(nabiContextProvider.notifier).setChatTyping(typing: true);

    try {
      final aiMessage = await _repository.sendMessage(message);
      _failedMessage = null;
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        canRetry: false,
      );
      ref.read(nabiContextProvider.notifier).setChatAnswerReady();
    } catch (error) {
      _failedMessage = message;
      state = state.copyWith(
        isLoading: false,
        error: _messageForSendError(error),
        canRetry: true,
      );
      ref.read(nabiContextProvider.notifier).setChatFailed();
    }
  }

  Future<void> clearChat() async {
    try {
      await _repository.clearHistory();
      _failedMessage = null;
      state = const AIChatState();
      ref.read(nabiContextProvider.notifier).clearTransientState();
    } catch (e) {
      state = state.copyWith(
        error: 'Không thể xóa lịch sử trò chuyện',
        canRetry: false,
      );
    }
  }

  void dismissError() {
    _failedMessage = null;
    state = state.copyWith(error: null, canRetry: false);
  }
}

String _messageForSendError(Object error) {
  if (error is UsageQuotaException) return error.userMessage;
  if (error is AIConfigurationUnavailableException) {
    return AIConfigurationUnavailableException.userMessage;
  }
  if (error is AIAuthenticationException) {
    return AIAuthenticationException.userMessage;
  }
  if (error is AINetworkException) return AINetworkException.userMessage;
  if (error is AIModelUnavailableException) {
    return AIModelUnavailableException.userMessage;
  }
  if (error is AIOverloadedException) return AIOverloadedException.userMessage;
  if (error is AIResponseInvalidException) {
    return AIResponseInvalidException.userMessage;
  }
  if (error is AIChatUnavailableException) return error.userMessage;
  return 'Không thể gửi tin nhắn. Bạn thử lại sau một chút nhé.';
}

final aiChatControllerProvider =
    NotifierProvider<AIChatController, AIChatState>(AIChatController.new);
