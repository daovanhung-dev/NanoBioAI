import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_chat_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_exceptions.dart';
import 'package:nano_app/app_versions/v1/services/ai/gemini_rest_client.dart';

void main() {
  group('AIChatService', () {
    test('chuyển sang model fallback khi model chính không tồn tại', () async {
      final attempts = <String>[];
      final service = AIChatService(
        modelNames: const ['retired-model', 'gemini-3.5-flash'],
        delay: (_) async {},
        modelCooldown: Duration.zero,
        textGenerator: ({required modelName, required message}) async {
          attempts.add(modelName);
          if (modelName == 'retired-model') {
            throw const GeminiApiException(
              statusCode: 404,
              status: 'NOT_FOUND',
              message: 'Requested model was not found.',
            );
          }
          return 'Mình khuyên bạn giữ giờ ngủ ổn định và hạn chế cà phê tối.';
        },
      );

      final response = await service.sendMessage('Làm sao để ngủ sâu hơn?');

      expect(response, contains('giờ ngủ ổn định'));
      expect(attempts, ['retired-model', 'gemini-3.5-flash']);
    });

    test(
      'chuyển lỗi xác thực thành typed exception và không thử model khác',
      () async {
        final attempts = <String>[];
        final service = AIChatService(
          modelNames: const ['gemini-3.5-flash', 'gemini-3.1-flash-lite'],
          delay: (_) async {},
          textGenerator: ({required modelName, required message}) async {
            attempts.add(modelName);
            throw const GeminiApiException(
              statusCode: 403,
              status: 'PERMISSION_DENIED',
              message: 'API key rejected.',
            );
          },
        );

        await expectLater(
          service.sendMessage('Xin chào'),
          throwsA(isA<AIAuthenticationException>()),
        );
        expect(attempts, ['gemini-3.5-flash']);
      },
    );

    test('chuyển lỗi kết nối thành AINetworkException', () async {
      final service = AIChatService(
        modelNames: const ['gemini-3.5-flash'],
        delay: (_) async {},
        modelCooldown: Duration.zero,
        textGenerator: ({required modelName, required message}) async {
          throw const GeminiApiException(
            status: 'network_error',
            message: 'Could not connect to Gemini.',
          );
        },
      );

      await expectLater(
        service.sendMessage('Xin chào'),
        throwsA(isA<AINetworkException>()),
      );
    });

    test('giới hạn lịch sử chat ở 16 message gần nhất', () async {
      final contentLengths = <int>[];
      final client = GeminiRestClient(
        apiKey: 'test-api-key-with-safe-length',
        post:
            ({
              required String url,
              required Map<String, String> headers,
              required Map<String, Object?> body,
            }) async {
              final contents = body['contents'] as List<Object?>;
              contentLengths.add(contents.length);
              return const GeminiHttpResponse(
                statusCode: 200,
                data: {
                  'candidates': [
                    {
                      'content': {
                        'parts': [
                          {
                            'text':
                                'Mình đã nhận câu hỏi và sẽ trả lời bằng tiếng Việt.',
                          },
                        ],
                      },
                    },
                  ],
                },
              );
            },
      );
      final service = AIChatService(
        modelNames: const ['gemini-3.5-flash'],
        geminiClient: client,
      );

      for (var index = 0; index < 12; index++) {
        await service.sendMessage('Câu hỏi số $index về giấc ngủ');
      }

      expect(contentLengths, hasLength(12));
      expect(contentLengths.last, 17);
      expect(contentLengths.every((length) => length <= 17), isTrue);
    });
  });
}
