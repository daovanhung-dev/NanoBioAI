import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/data/datasources/voice_chat_turn_datasource.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/entities/voice_chat_message.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/voice_chat_exception.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_text_client.dart';
import 'package:nano_app/core/ai_local/local_ai_text_client.dart';

void main() {
  group('LocalVoiceChatTurnDatasource', () {
    test('sends a bounded turn through the local AI contract', () async {
      _AiRequest? captured;
      final datasource = LocalVoiceChatTurnDatasource(
        client: _FakeAiTextClient((request) async {
          captured = request;
          return '  Nabi trả lời ngắn gọn.  ';
        }),
      );

      final result = await datasource.sendTurn(
        message: '  Tôi nên ngủ lúc nào?  ',
        history: const [
          VoiceChatMessage(role: VoiceChatRole.user, text: 'Xin chào'),
          VoiceChatMessage(role: VoiceChatRole.model, text: 'Nabi chào bạn.'),
        ],
      );

      expect(result, 'Nabi trả lời ngắn gọn.');
      expect(captured?.model, LocalAiTextClient.modelId);
      expect(captured?.messages.map((item) => item.text), [
        'Xin chào',
        'Nabi chào bạn.',
        'Tôi nên ngủ lúc nào?',
      ]);
      expect(captured?.systemInstruction, contains('Không chẩn đoán'));
    });

    test('rejects oversized history before invoking the local model', () async {
      var calls = 0;
      final datasource = LocalVoiceChatTurnDatasource(
        client: _FakeAiTextClient((_) async {
          calls++;
          return 'Đã rõ.';
        }),
      );

      await expectLater(
        datasource.sendTurn(
          message: 'Xin chào',
          history: List.generate(
            LocalVoiceChatTurnDatasource.maxHistoryMessages + 1,
            (index) => VoiceChatMessage(
              role: VoiceChatRole.user,
              text: 'Tin nhắn $index',
            ),
          ),
        ),
        throwsA(
          isA<VoiceChatException>().having(
            (error) => error.failure,
            'failure',
            VoiceChatFailure.invalidRequest,
          ),
        ),
      );
      expect(calls, 0);
    });

    test('maps unsupported platform to a clear voice failure', () async {
      final datasource = LocalVoiceChatTurnDatasource(
        client: _FakeAiTextClient(
          (_) async => throw const AiInferenceException(
            status: 'unsupported_platform',
            message: 'AI trên thiết bị chưa hỗ trợ bản web.',
          ),
        ),
      );

      await expectLater(
        datasource.sendTurn(message: 'Xin chào', history: const []),
        throwsA(
          isA<VoiceChatException>().having(
            (error) => error.failure,
            'failure',
            VoiceChatFailure.unsupportedPlatform,
          ),
        ),
      );
    });

    test('maps local model timeout and invalid output safely', () async {
      final pending = Completer<String>();
      final timeoutDatasource = LocalVoiceChatTurnDatasource(
        client: _FakeAiTextClient((_) => pending.future),
        requestTimeout: const Duration(milliseconds: 2),
      );
      await expectLater(
        timeoutDatasource.sendTurn(message: 'Xin chào', history: const []),
        throwsA(
          isA<VoiceChatException>().having(
            (error) => error.failure,
            'failure',
            VoiceChatFailure.temporarilyUnavailable,
          ),
        ),
      );

      final invalidDatasource = LocalVoiceChatTurnDatasource(
        client: _FakeAiTextClient((_) async => ''),
      );
      await expectLater(
        invalidDatasource.sendTurn(message: 'Xin chào', history: const []),
        throwsA(
          isA<VoiceChatException>().having(
            (error) => error.failure,
            'failure',
            VoiceChatFailure.invalidResponse,
          ),
        ),
      );
    });
  });
}

class _FakeAiTextClient implements AiTextClient {
  _FakeAiTextClient(this.generate);

  final Future<String> Function(_AiRequest request) generate;

  @override
  Future<String> generateText({
    required String model,
    required List<AiMessage> messages,
    required AiGenerationConfig generationConfig,
    String? systemInstruction,
  }) => generate(
    _AiRequest(
      model: model,
      messages: messages,
      systemInstruction: systemInstruction,
    ),
  );

  @override
  Stream<String> streamText({
    required String model,
    required List<AiMessage> messages,
    required AiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async* {
    yield await generateText(
      model: model,
      messages: messages,
      generationConfig: generationConfig,
      systemInstruction: systemInstruction,
    );
  }
}

class _AiRequest {
  const _AiRequest({
    required this.model,
    required this.messages,
    required this.systemInstruction,
  });

  final String model;
  final List<AiMessage> messages;
  final String? systemInstruction;
}
