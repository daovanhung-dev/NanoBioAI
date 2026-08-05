import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/domain/entities/chat_message_entity.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/domain/repositories/ai_chat_repository.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/providers/ai_chat_providers.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/data/gateways/speech_to_text_gateway.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/entities/ai_voice_state.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/gateways/voice_gateways.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/presentation/controllers/ai_voice_controller.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/providers/ai_voice_providers.dart';

void main() {
  test('greets once without consuming chat repository', () async {
    final speech = _FakeSpeechGateway();
    final tts = _FakeTtsGateway();
    final chat = _FakeChatRepository();
    final container = _container(speech: speech, tts: tts, chat: chat);
    addTearDown(container.dispose);
    final controller = container.read(aiVoiceControllerProvider.notifier);

    await controller.initializeAndGreet();
    await controller.initializeAndGreet();

    expect(tts.spoken, <String>[AiVoiceController.greeting]);
    expect(chat.sendCalls, 0);
    expect(container.read(aiVoiceControllerProvider).isInitialized, isTrue);
  });


  test('surfaces microphone permission denial without calling AI', () async {
    final speech = _PermissionDeniedSpeechGateway();
    final chat = _FakeChatRepository();
    final container = _container(
      speech: speech,
      tts: _FakeTtsGateway(),
      chat: chat,
    );
    addTearDown(container.dispose);
    final controller = container.read(aiVoiceControllerProvider.notifier);

    await controller.initializeAndGreet();

    final state = container.read(aiVoiceControllerProvider);
    expect(state.phase, AiVoicePhase.permissionDenied);
    expect(state.errorMessage, isNotEmpty);
    expect(chat.sendCalls, 0);
  });

  test('recognizes one phrase, reuses AI chat repository and speaks answer', () async {
    final speech = _FakeSpeechGateway(result: 'Tôi nên ăn gì?');
    final tts = _FakeTtsGateway();
    final chat = _FakeChatRepository(answer: 'Bạn có thể chọn một bữa nhẹ.');
    final container = _container(speech: speech, tts: tts, chat: chat);
    addTearDown(container.dispose);
    final controller = container.read(aiVoiceControllerProvider.notifier);

    await controller.listenAndRespond();

    final state = container.read(aiVoiceControllerProvider);
    expect(chat.messages, <String>['Tôi nên ăn gì?']);
    expect(state.transcript, 'Tôi nên ăn gì?');
    expect(state.response, 'Bạn có thể chọn một bữa nhẹ.');
    expect(state.phase, AiVoicePhase.idle);
    expect(tts.spoken.last, state.response);
  });

  test('stop invalidates a stale AI response', () async {
    final response = Completer<ChatMessageEntity>();
    final container = _container(
      speech: _FakeSpeechGateway(result: 'Câu hỏi'),
      tts: _FakeTtsGateway(),
      chat: _FakeChatRepository(completer: response),
    );
    addTearDown(container.dispose);
    final controller = container.read(aiVoiceControllerProvider.notifier);

    final operation = controller.listenAndRespond();
    await Future<void>.delayed(Duration.zero);
    await controller.stop();
    response.complete(_answer('Phản hồi đến muộn'));
    await operation;

    final state = container.read(aiVoiceControllerProvider);
    expect(state.phase, AiVoicePhase.idle);
    expect(state.response, isEmpty);
  });
}

ProviderContainer _container({
  required SpeechRecognitionGateway speech,
  required TextToSpeechGateway tts,
  required AIChatRepository chat,
}) {
  return ProviderContainer(
    overrides: [
      speechRecognitionGatewayProvider.overrideWithValue(speech),
      textToSpeechGatewayProvider.overrideWithValue(tts),
      aiChatRepositoryProvider.overrideWithValue(chat),
    ],
  );
}

class _FakeSpeechGateway implements SpeechRecognitionGateway {
  final String result;

  _FakeSpeechGateway({this.result = ''});

  @override
  Future<bool> initialize() async => true;

  @override
  Future<String> listenOnce({
    String localeId = 'vi_VN',
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 4),
  }) async => result;

  @override
  Future<void> cancel() async {}

  @override
  Future<void> stop() async {}
}

class _FakeTtsGateway implements TextToSpeechGateway {
  final List<String> spoken = <String>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

class _FakeChatRepository implements AIChatRepository {
  final String answer;
  final Completer<ChatMessageEntity>? completer;
  final List<String> messages = <String>[];
  int sendCalls = 0;

  _FakeChatRepository({
    this.answer = 'NaBi trả lời',
    this.completer,
  });

  @override
  Future<ChatMessageEntity> sendMessage(String message) {
    sendCalls++;
    messages.add(message);
    return completer?.future ?? Future<ChatMessageEntity>.value(_answer(answer));
  }

  @override
  Future<List<ChatMessageEntity>> getChatHistory() async => const [];

  @override
  Future<void> clearHistory() async {}
}

ChatMessageEntity _answer(String content) {
  return ChatMessageEntity(
    id: 'answer-1',
    content: content,
    role: MessageRole.assistant,
    timestamp: DateTime(2026, 8, 2),
  );
}

class _PermissionDeniedSpeechGateway implements SpeechRecognitionGateway {
  @override
  Future<bool> initialize() {
    throw const SpeechRecognitionPermissionDeniedException(
      permanentlyDenied: true,
    );
  }

  @override
  Future<String> listenOnce({
    String localeId = 'vi_VN',
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 4),
  }) {
    throw const SpeechRecognitionPermissionDeniedException(
      permanentlyDenied: true,
    );
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<void> stop() async {}
}
