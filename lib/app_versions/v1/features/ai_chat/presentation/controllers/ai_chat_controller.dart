import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/nabi/providers/nabi_provider.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_exceptions.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/services/backend/usage_quota/usage_quota_gateway.dart';

import '../../domain/entities/ai_chat_stream_event.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../ai_chat_thinking_phrases.dart';
import '../../providers/ai_chat_providers.dart';

class AIChatState {
  static const Object _unchanged = Object();

  final List<ChatMessageEntity> messages;
  final bool isLoading;
  final String? error;
  final String? thinkingPhrase;
  final bool canRetry;
  final bool showPlusUpgrade;

  const AIChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.thinkingPhrase,
    this.canRetry = false,
    this.showPlusUpgrade = false,
  });

  AIChatState copyWith({
    List<ChatMessageEntity>? messages,
    bool? isLoading,
    Object? error = _unchanged,
    Object? thinkingPhrase = _unchanged,
    bool? canRetry,
    bool? showPlusUpgrade,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unchanged) ? this.error : error as String?,
      thinkingPhrase: identical(thinkingPhrase, _unchanged)
          ? this.thinkingPhrase
          : thinkingPhrase as String?,
      canRetry: canRetry ?? this.canRetry,
      showPlusUpgrade: showPlusUpgrade ?? this.showPlusUpgrade,
    );
  }
}

class AIChatController extends Notifier<AIChatState> {
  String? _failedMessage;
  String? _failedThinkingPhrase;
  bool _isReservingThinkingPhrase = false;
  int _fallbackNextThinkingPhraseIndex = 0;

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
    if (state.isLoading ||
        _isReservingThinkingPhrase ||
        message.trim().isEmpty) {
      return;
    }

    final trimmed = message.trim();
    _failedMessage = null;
    _failedThinkingPhrase = null;
    _isReservingThinkingPhrase = true;

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
      thinkingPhrase: null,
      canRetry: false,
      showPlusUpgrade: false,
    );
    ref.read(nabiContextProvider.notifier).setChatTyping(typing: true);

    final thinkingPhrase = await _reserveThinkingPhrase();
    _isReservingThinkingPhrase = false;
    if (!state.isLoading) return;
    _failedThinkingPhrase = thinkingPhrase;
    state = state.copyWith(thinkingPhrase: thinkingPhrase);
    await _streamAssistantResponse(trimmed);
  }

  Future<void> retryLastMessage() async {
    final message = _failedMessage;
    if (state.isLoading || message == null || message.isEmpty) return;
    final thinkingPhrase =
        _failedThinkingPhrase ??
        state.thinkingPhrase ??
        AIChatThinkingPhrases.values.first;

    state = state.copyWith(
      isLoading: true,
      error: null,
      thinkingPhrase: thinkingPhrase,
      canRetry: false,
      showPlusUpgrade: false,
    );
    ref.read(nabiContextProvider.notifier).setChatTyping(typing: true);

    await _streamAssistantResponse(message);
  }

  Future<void> _streamAssistantResponse(String message) async {
    final timestamp = DateTime.now();
    final assistantMessageId = 'ai-chat-${timestamp.microsecondsSinceEpoch}';
    var completed = false;

    try {
      await for (final event in _repository.sendMessageStream(message)) {
        final isPartial = event.type == AIChatStreamEventType.delta;
        final text = event.fullText.trim();
        if (text.isEmpty) continue;

        _upsertAssistantMessage(
          id: assistantMessageId,
          timestamp: timestamp,
          content: text,
          isStreaming: isPartial,
        );
        if (!isPartial) completed = true;
      }

      if (!completed) throw const AIResponseInvalidException();
      _failedMessage = null;
      _failedThinkingPhrase = null;
      ref.read(nabiContextProvider.notifier).setChatAnswerReady();
    } catch (error) {
      final isQuotaExceeded = error is UsageQuotaExceededException;
      _failedMessage = message;
      final thinkingPhrase = state.thinkingPhrase;
      _failedThinkingPhrase = isQuotaExceeded ? null : thinkingPhrase;
      state = state.copyWith(
        messages: state.messages
            .where((message) => message.id != assistantMessageId)
            .toList(growable: false),
        isLoading: false,
        error: _messageForSendError(error),
        thinkingPhrase: isQuotaExceeded ? null : thinkingPhrase,
        canRetry: !isQuotaExceeded,
        showPlusUpgrade: isQuotaExceeded,
      );
      ref.read(nabiContextProvider.notifier).setChatFailed();
    }
  }

  void _upsertAssistantMessage({
    required String id,
    required DateTime timestamp,
    required String content,
    required bool isStreaming,
  }) {
    final messages = List<ChatMessageEntity>.of(state.messages);
    final index = messages.indexWhere((message) => message.id == id);
    final assistantMessage = ChatMessageEntity(
      id: id,
      content: content,
      role: MessageRole.assistant,
      timestamp: timestamp,
      isLoading: isStreaming,
    );
    if (index < 0) {
      messages.add(assistantMessage);
    } else {
      messages[index] = assistantMessage;
    }
    state = state.copyWith(
      messages: messages,
      isLoading: isStreaming,
      error: null,
      thinkingPhrase: isStreaming ? state.thinkingPhrase : null,
      canRetry: false,
      showPlusUpgrade: false,
    );
  }

  Future<void> clearChat() async {
    try {
      await _repository.clearHistory();
      _failedMessage = null;
      _failedThinkingPhrase = null;
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
    _failedThinkingPhrase = null;
    state = state.copyWith(
      error: null,
      thinkingPhrase: null,
      canRetry: false,
      showPlusUpgrade: false,
    );
  }

  Future<String> _reserveThinkingPhrase() async {
    final phraseCount = AIChatThinkingPhrases.values.length;
    try {
      final index = await AppPrefs.reserveNextAiChatThinkingPhraseIndex(
        phraseCount: phraseCount,
      );
      _fallbackNextThinkingPhraseIndex = (index + 1) % phraseCount;
      return AIChatThinkingPhrases.values[index];
    } catch (_) {
      final index = _fallbackNextThinkingPhraseIndex;
      _fallbackNextThinkingPhraseIndex = (index + 1) % phraseCount;
      return AIChatThinkingPhrases.values[index];
    }
  }
}

String _messageForSendError(Object error) {
  if (error is UsageQuotaException) return error.userMessage;
  if (error is AIConfigurationUnavailableException) {
    return AIConfigurationUnavailableException.userMessage;
  }
  if (error is AIInferenceTimeoutException) {
    return AIInferenceTimeoutException.userMessage;
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
