import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/data/datasources/voice_chat_turn_datasource.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/data/repositories/ai_voice_repository_impl.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/entities/voice_chat_message.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/voice_chat_exception.dart';

void main() {
  group('AiVoiceRepositoryImpl', () {
    test(
      'keeps only six completed turns and clears between sessions',
      () async {
        final datasource = _FakeDatasource();
        final repository = AiVoiceRepositoryImpl(datasource);

        for (var turn = 1; turn <= 8; turn++) {
          await repository.sendTurn('Câu $turn');
        }

        final historySentWithTurnEight = datasource.histories[7];
        expect(historySentWithTurnEight, hasLength(12));
        expect(
          historySentWithTurnEight.first,
          const VoiceChatMessage(role: VoiceChatRole.user, text: 'Câu 2'),
        );
        expect(
          historySentWithTurnEight.last,
          const VoiceChatMessage(role: VoiceChatRole.model, text: 'Đáp 7'),
        );

        repository.resetSession();
        await repository.sendTurn('Phiên mới');
        expect(datasource.histories.last, isEmpty);
      },
    );

    test('does not append a failed turn', () async {
      final datasource = _FakeDatasource();
      final repository = AiVoiceRepositoryImpl(datasource);
      await repository.sendTurn('Câu thành công');
      datasource.failure = const VoiceChatException(
        VoiceChatFailure.unavailable,
      );

      await expectLater(
        repository.sendTurn('Câu lỗi'),
        throwsA(isA<VoiceChatException>()),
      );
      datasource.failure = null;
      await repository.sendTurn('Câu tiếp theo');

      expect(datasource.histories.last, hasLength(2));
      expect(datasource.histories.last.first.text, 'Câu thành công');
    });

    test('late response cannot repopulate history after reset', () async {
      final datasource = _FakeDatasource();
      final repository = AiVoiceRepositoryImpl(datasource);
      final pending = Completer<String>();
      datasource.pendingResponse = pending;

      final staleTurn = repository.sendTurn('Câu đã hủy');
      await Future<void>.delayed(Duration.zero);
      repository.resetSession();
      pending.complete('Đáp đến muộn');
      await staleTurn;

      datasource.pendingResponse = null;
      await repository.sendTurn('Phiên mới');
      expect(datasource.histories.last, isEmpty);
    });

    test(
      'accepts input over 2000 characters and rejects input over 6000',
      () async {
        final datasource = _FakeDatasource();
        final repository = AiVoiceRepositoryImpl(datasource);
        final acceptedMessage = List<String>.filled(3000, 'a').join();

        await repository.sendTurn(acceptedMessage);
        expect(datasource.messages, [acceptedMessage]);

        await expectLater(
          repository.sendTurn(List<String>.filled(6001, 'a').join()),
          throwsA(
            isA<VoiceChatException>().having(
              (error) => error.failure,
              'failure',
              VoiceChatFailure.invalidRequest,
            ),
          ),
        );
        expect(datasource.messages, [acceptedMessage]);
      },
    );

    test('rejects empty messages before datasource', () async {
      final datasource = _FakeDatasource();
      final repository = AiVoiceRepositoryImpl(datasource);

      await expectLater(
        repository.sendTurn('   '),
        throwsA(
          isA<VoiceChatException>().having(
            (error) => error.failure,
            'failure',
            VoiceChatFailure.invalidRequest,
          ),
        ),
      );
      expect(datasource.messages, isEmpty);
    });

    test('rejects Gemini responses over 2000 characters', () async {
      final datasource = _FakeDatasource()
        ..response = List<String>.filled(2001, 'a').join();
      final repository = AiVoiceRepositoryImpl(datasource);

      await expectLater(
        repository.sendTurn('Câu hỏi hợp lệ'),
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

class _FakeDatasource implements VoiceChatTurnDatasource {
  final List<String> messages = [];
  final List<List<VoiceChatMessage>> histories = [];
  VoiceChatException? failure;
  Completer<String>? pendingResponse;
  String? response;

  @override
  Future<String> sendTurn({
    required String message,
    required List<VoiceChatMessage> history,
  }) async {
    messages.add(message);
    histories.add(List<VoiceChatMessage>.from(history));
    final currentFailure = failure;
    if (currentFailure != null) throw currentFailure;
    final pending = pendingResponse;
    if (pending != null) return pending.future;
    final configuredResponse = response;
    if (configuredResponse != null) return configuredResponse;
    return 'Đáp ${messages.length}';
  }
}
