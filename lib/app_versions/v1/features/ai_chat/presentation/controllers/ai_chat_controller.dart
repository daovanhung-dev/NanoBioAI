import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/services/supabase/usage_quota/usage_quota_gateway.dart';

import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../../providers/ai_chat_providers.dart';

class AIChatState {
  final List<ChatMessageEntity> messages;
  final bool isLoading;
  final String? error;

  const AIChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AIChatState copyWith({
    List<ChatMessageEntity>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AIChatController extends Notifier<AIChatState> {
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
      state = state.copyWith(error: 'Không thể tải lịch sử chat');
    }
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final trimmed = message.trim();

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
    );

    try {
      final aiMessage = await _repository.sendMessage(trimmed);

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _messageForSendError(e));
    }
  }

  Future<void> clearChat() async {
    try {
      await _repository.clearHistory();
      state = const AIChatState();
    } catch (e) {
      state = state.copyWith(error: 'Không thể xóa lịch sử chat');
    }
  }

  void dismissError() {
    state = state.copyWith(error: null);
  }
}

String _messageForSendError(Object error) {
  if (error is UsageQuotaException) return error.userMessage;
  return 'Không thể gửi tin nhắn. Bạn thử lại sau một chút nhé.';
}

final aiChatControllerProvider =
    NotifierProvider<AIChatController, AIChatState>(AIChatController.new);
