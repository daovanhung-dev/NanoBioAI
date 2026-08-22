import '../entities/ai_chat_stream_event.dart';
import '../entities/chat_message_entity.dart';

class AIChatUnavailableException implements Exception {
  static const message =
      'Nabi chưa thể kết nối lúc này. Bạn thử lại sau một chút nhé.';

  const AIChatUnavailableException();

  String get userMessage => message;

  @override
  String toString() => userMessage;
}

/// Original repository contract is intentionally preserved so existing tests,
/// fakes and non-voice call sites do not break.
abstract class AIChatRepository {
  Future<ChatMessageEntity> sendMessage(String message);

  Future<List<ChatMessageEntity>> getChatHistory();

  Future<void> clearHistory();
}

/// Optional true-streaming capability implemented by the production repo.
abstract class AIChatStreamingCapability {
  Stream<AIChatStreamEvent> sendRealtimeMessageStream(String message);
}

extension AIChatStreamingExtension on AIChatRepository {
  Stream<AIChatStreamEvent> sendMessageStream(String message) {
    final repository = this;
    if (repository is AIChatStreamingCapability) {
      return (repository as AIChatStreamingCapability)
          .sendRealtimeMessageStream(message);
    }

    // Compatibility adapter for existing fakes/tests that only implement the
    // original one-shot repository contract.
    return (() async* {
      final response = await repository.sendMessage(message);
      yield AIChatStreamEvent.delta(
        delta: response.content,
        fullText: response.content,
      );
      yield AIChatStreamEvent.completed(fullText: response.content);
    })();
  }
}
