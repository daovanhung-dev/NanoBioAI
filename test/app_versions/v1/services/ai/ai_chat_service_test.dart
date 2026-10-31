import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_chat_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_exceptions.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_text_client.dart';
import 'package:nano_app/core/network/backend_ai_text_client.dart';
import 'package:nano_app/core/utils/logger/terminal_log_sink.dart';

void main() {
  group('AIChatService backend client', () {
    test(
      'uses the selected backend model contract for text generation',
      () async {
        final client = _FakeAiTextClient(
          generate: (request) async {
            expect(request.model, BackendAiTextClient.modelId);
            expect(request.messages.single.text, 'Làm sao để ngủ sâu hơn?');
            return 'Mình khuyên bạn giữ giờ ngủ ổn định.';
          },
        );
        final service = AIChatService(aiClient: client);

        final response = await service.sendMessage('Làm sao để ngủ sâu hơn?');

        expect(response, 'Mình khuyên bạn giữ giờ ngủ ổn định.');
        expect(client.generateCalls, 1);
      },
    );

    test('preserves inference failures without fallback', () async {
      final client = _FakeAiTextClient(
        generate: (_) async => throw const AiInferenceException(
          status: 'unsupported_platform',
          message: 'AI trên thiết bị chưa hỗ trợ bản web.',
        ),
      );
      final service = AIChatService(aiClient: client);

      await expectLater(
        service.sendMessage('Xin chào'),
        throwsA(isA<AIPlatformUnsupportedException>()),
      );
      expect(client.generateCalls, 1);
    });

    test(
      'allows local inference to continue while tokens keep arriving',
      () async {
        expect(
          AIChatRetryPolicy.perAttemptTimeout,
          const Duration(seconds: 120),
        );
        final client = _FakeAiTextClient(
          generate: (_) async => 'Mình đã nhận được câu hỏi của bạn.',
          stream: (_) async* {
            await Future<void>.delayed(const Duration(milliseconds: 35));
            yield 'Mình đã ';
            await Future<void>.delayed(const Duration(milliseconds: 35));
            yield 'nhận được câu hỏi ';
            await Future<void>.delayed(const Duration(milliseconds: 35));
            yield 'của bạn.';
          },
        );
        final service = AIChatService(
          aiClient: client,
          perAttemptTimeout: const Duration(milliseconds: 60),
        );

        await expectLater(
          service.sendMessage('Câu hỏi thử nghiệm ngắn'),
          completion('Mình đã nhận được câu hỏi của bạn.'),
        );
      },
    );

    test('reports local inference timeout with safe diagnostics', () async {
      final logLines = <String>[];
      TerminalLogSink.setTestWriter(logLines.add);
      addTearDown(() => TerminalLogSink.setTestWriter(null));

      final client = _FakeAiTextClient(
        generate: (_) async => '',
        stream: (_) => StreamController<String>().stream,
      );
      final service = AIChatService(
        aiClient: client,
        perAttemptTimeout: const Duration(milliseconds: 20),
      );
      const testPrompt = 'synthetic private test prompt';

      await expectLater(
        service.sendMessage(testPrompt),
        throwsA(isA<AIInferenceTimeoutException>()),
      );

      final failureLog = logLines
          .where((line) => line.contains('RETRY_ATTEMPT_FAILED'))
          .join('\n');
      expect(failureLog, contains('model=${BackendAiTextClient.modelId}'));
      expect(failureLog, contains('status=backend_inference_timeout'));
      expect(failureLog, contains('durationMs='));
      expect(failureLog, contains('errorType=TimeoutException'));
      expect(failureLog, isNot(contains(testPrompt)));
      expect(client.streamCalls, 1);
    });

    test(
      'allows a delayed first streaming token within the local timeout',
      () async {
        final client = _FakeAiTextClient(
          generate: (_) async => 'Mình đã nhận được câu hỏi của bạn.',
          stream: (_) async* {
            await Future<void>.delayed(const Duration(milliseconds: 35));
            yield 'Mình đã nhận được câu hỏi của bạn.';
          },
        );
        final service = AIChatService(
          aiClient: client,
          perAttemptTimeout: const Duration(milliseconds: 100),
        );
        final prepared = await service.prepareMessageStream(
          'Câu hỏi thử nghiệm',
        );

        await expectLater(
          prepared.stream,
          emitsInOrder(['Mình đã nhận được câu hỏi của bạn.', emitsDone]),
        );
        prepared.accept();
      },
    );

    test('allows the first local token after a 20 second idle gap', () async {
      final client = _FakeAiTextClient(
        generate: (_) async => 'Mình đã nhận được câu hỏi của bạn.',
        stream: (_) async* {
          await Future<void>.delayed(const Duration(seconds: 20));
          yield 'Mình đã nhận được câu hỏi của bạn.';
        },
      );
      final service = AIChatService(aiClient: client);

      await expectLater(
        service.sendMessage('Câu hỏi thử nghiệm ngắn'),
        completion('Mình đã nhận được câu hỏi của bạn.'),
      );
    });

    test(
      'separates backend model availability from transient runtime errors',
      () async {
        final modelClient = _FakeAiTextClient(
          generate: (_) async => throw const AiInferenceException(
            status: 'model_unavailable',
            message: 'Synthetic backend model unavailable.',
          ),
        );
        final runtimeClient = _FakeAiTextClient(
          generate: (_) async => throw const AiInferenceException(
            status: 'runtime_error',
            message: 'Synthetic runtime failure.',
          ),
        );

        await expectLater(
          AIChatService(
            aiClient: modelClient,
          ).sendMessage('Câu hỏi thử nghiệm'),
          throwsA(isA<AIModelUnavailableException>()),
        );
        await expectLater(
          AIChatService(
            aiClient: runtimeClient,
          ).sendMessage('Câu hỏi thử nghiệm'),
          throwsA(isA<AIOverloadedException>()),
        );
        expect(modelClient.streamCalls, 1);
        expect(runtimeClient.streamCalls, 1);
      },
    );

    test('limits history to 16 recent messages', () async {
      final messageCounts = <int>[];
      final client = _FakeAiTextClient(
        generate: (request) async {
          messageCounts.add(request.messages.length);
          return 'Mình đã nhận câu hỏi và sẽ trả lời bằng tiếng Việt.';
        },
      );
      final service = AIChatService(aiClient: client);

      for (var index = 0; index < 12; index++) {
        await service.sendMessage('Câu hỏi số $index về giấc ngủ');
      }

      expect(messageCounts, hasLength(12));
      expect(messageCounts.last, 17);
      expect(messageCounts.every((length) => length <= 17), isTrue);
    });

    test('does not retain output when local generation is truncated', () async {
      final client = _FakeAiTextClient(
        generate: (_) async => throw const AiInferenceException(
          status: 'output_truncated',
          message: 'Local model output was truncated.',
        ),
      );
      final service = AIChatService(aiClient: client);

      await expectLater(
        service.sendMessage('Câu hỏi dài'),
        throwsA(isA<AIResponseInvalidException>()),
      );
      expect(client.generateCalls, 1);
    });

    test('sanitizes AI text without changing the original question', () async {
      String? receivedMessage;
      final client = _FakeAiTextClient(
        generate: (request) async {
          receivedMessage = request.messages.last.text;
          return 'Xin chào *bạn* & ^ 😊.';
        },
      );
      final service = AIChatService(aiClient: client);

      final response = await service.sendMessage('Giữ nguyên *câu hỏi* & ^');

      expect(receivedMessage, 'Giữ nguyên *câu hỏi* & ^');
      expect(response, 'Xin chào bạn.');
    });
  });
}

class _FakeAiTextClient implements AiTextClient {
  _FakeAiTextClient({required this.generate, this.stream});

  final Future<String> Function(_AiRequest request) generate;
  final Stream<String> Function(_AiRequest request)? stream;
  int generateCalls = 0;
  int streamCalls = 0;

  @override
  Future<String> generateText({
    required String model,
    required List<AiMessage> messages,
    required AiGenerationConfig generationConfig,
    String? systemInstruction,
  }) {
    generateCalls++;
    return generate(_AiRequest(model: model, messages: messages));
  }

  @override
  Stream<String> streamText({
    required String model,
    required List<AiMessage> messages,
    required AiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async* {
    streamCalls++;
    final customStream = stream;
    if (customStream != null) {
      yield* customStream(_AiRequest(model: model, messages: messages));
      return;
    }
    yield await generateText(
      model: model,
      messages: messages,
      generationConfig: generationConfig,
      systemInstruction: systemInstruction,
    );
  }
}

class _AiRequest {
  const _AiRequest({required this.model, required this.messages});

  final String model;
  final List<AiMessage> messages;
}
