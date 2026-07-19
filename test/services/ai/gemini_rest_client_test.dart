import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_chat_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/gemini_rest_client.dart';

void main() {
  group('GeminiRestClient', () {
    test(
      'accepts authorization keys and sends x-goog-api-key header',
      () async {
        const authorizationKey = 'AQ.test-authorization-key';
        String? capturedUrl;
        Map<String, String>? capturedHeaders;
        Map<String, Object?>? capturedBody;

        final client = GeminiRestClient(
          apiKey: authorizationKey,
          baseUrl: 'https://example.test/v1beta/',
          post: ({required url, required headers, required body}) async {
            capturedUrl = url;
            capturedHeaders = headers;
            capturedBody = body;
            return const GeminiHttpResponse(
              statusCode: 200,
              data: {
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {'text': 'Xin chào từ Gemini.'},
                      ],
                    },
                  },
                ],
              },
            );
          },
        );

        final result = await client.generateText(
          model: 'models/gemini-3.5-flash',
          contents: const [GeminiContent.user('Xin chào')],
          systemInstruction: 'Luôn trả lời bằng tiếng Việt.',
          generationConfig: const GeminiGenerationConfig(
            maxOutputTokens: 128,
            temperature: 0.2,
            topP: 0.8,
          ),
        );

        expect(result, 'Xin chào từ Gemini.');
        expect(
          capturedUrl,
          'https://example.test/v1beta/models/gemini-3.5-flash:generateContent',
        );
        expect(capturedHeaders?['x-goog-api-key'], authorizationKey);
        expect(capturedHeaders?['Content-Type'], 'application/json');
        expect(capturedBody?['systemInstruction'], isNotNull);
        expect(capturedBody?['contents'], isA<List>());
      },
    );

    test('joins text parts from a successful response', () async {
      final client = GeminiRestClient(
        apiKey: 'AQ.fake-key',
        post: ({required url, required headers, required body}) async {
          return const GeminiHttpResponse(
            statusCode: 200,
            data: {
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Phần một.'},
                      {'text': 'Phần hai.'},
                    ],
                  },
                },
              ],
            },
          );
        },
      );

      final result = await client.generateText(
        model: 'gemini-3.1-flash-lite',
        contents: const [GeminiContent.user('Kiểm tra')],
        generationConfig: const GeminiGenerationConfig(
          maxOutputTokens: 32,
          temperature: 0.2,
          topP: 0.8,
        ),
      );

      expect(result, 'Phần một.\nPhần hai.');
    });

    test('exposes transient status without leaking request headers', () async {
      final client = GeminiRestClient(
        apiKey: 'AQ.fake-key',
        post: ({required url, required headers, required body}) async {
          return const GeminiHttpResponse(
            statusCode: 429,
            data: {
              'error': {
                'status': 'RESOURCE_EXHAUSTED',
                'message': 'Quota temporarily exhausted.',
              },
            },
          );
        },
      );

      Object? capturedError;
      try {
        await client.generateText(
          model: 'gemini-3.1-flash-lite',
          contents: const [GeminiContent.user('Kiểm tra')],
          generationConfig: const GeminiGenerationConfig(
            maxOutputTokens: 32,
            temperature: 0.2,
            topP: 0.8,
          ),
        );
      } catch (error) {
        capturedError = error;
      }

      expect(capturedError, isA<GeminiApiException>());
      final exception = capturedError as GeminiApiException;
      expect(exception.statusCode, 429);
      expect(exception.status, 'RESOURCE_EXHAUSTED');
      expect(exception.isTransient, isTrue);
      expect(exception.toString(), isNot(contains('AQ.fake-key')));
    });
  });

  group('AI service REST integration', () {
    test(
      'onboarding connection check uses the shared Gemini REST client',
      () async {
        final client = GeminiRestClient(
          apiKey: 'AQ.fake-key',
          post: ({required url, required headers, required body}) async {
            return const GeminiHttpResponse(
              statusCode: 200,
              data: {
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {'text': '[{"status_code":"ai_connection_ok"}]'},
                      ],
                    },
                  },
                ],
              },
            );
          },
        );
        final service = AIService(
          modelNames: const ['gemini-test'],
          geminiClient: client,
          delay: (_) async {},
        );

        final result = await service.checkConnection();

        expect(result.success, isTrue);
        expect(result.modelName, 'gemini-test');
      },
    );

    test(
      'chat uses REST system instruction and bounded conversation history',
      () async {
        final requestBodies = <Map<String, Object?>>[];
        final client = GeminiRestClient(
          apiKey: 'AQ.fake-key',
          post: ({required url, required headers, required body}) async {
            requestBodies.add(body);
            return const GeminiHttpResponse(
              statusCode: 200,
              data: {
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {'text': 'Mình đang ở đây để hỗ trợ bạn nhé.'},
                      ],
                    },
                  },
                ],
              },
            );
          },
        );
        final service = AIChatService(
          modelNames: const ['gemini-test'],
          geminiClient: client,
          delay: (_) async {},
        );

        await service.sendMessage('Xin chào');
        await service.sendMessage('Bạn còn nhớ câu trước không?');

        expect(requestBodies, hasLength(2));
        expect(requestBodies.first['systemInstruction'], isNotNull);
        final secondContents = requestBodies.last['contents'] as List;
        expect(secondContents, hasLength(3));
        expect((secondContents.first as Map)['role'], 'user');
        expect((secondContents[1] as Map)['role'], 'model');
        expect((secondContents.last as Map)['role'], 'user');
      },
    );

    test(
      'prepared chat response enters history only after acknowledgement',
      () async {
        final requestBodies = <Map<String, Object?>>[];
        final client = GeminiRestClient(
          apiKey: 'AQ.fake-key',
          post: ({required url, required headers, required body}) async {
            requestBodies.add(body);
            return const GeminiHttpResponse(
              statusCode: 200,
              data: {
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {'text': 'Mình đang ở đây để hỗ trợ bạn nhé.'},
                      ],
                    },
                  },
                ],
              },
            );
          },
        );
        final service = AIChatService(
          modelNames: const ['gemini-test'],
          geminiClient: client,
          delay: (_) async {},
        );

        final first = await service.prepareMessage('Tin nhắn đầu tiên');
        await service.prepareMessage('Tin nhắn chưa được chấp nhận');

        final beforeAcknowledgement = requestBodies.last['contents'] as List;
        expect(beforeAcknowledgement, hasLength(1));

        first
          ..accept()
          ..accept();
        await service.prepareMessage('Tin nhắn sau khi chấp nhận');

        final afterAcknowledgement = requestBodies.last['contents'] as List;
        expect(afterAcknowledgement, hasLength(3));
        expect((afterAcknowledgement[0] as Map)['role'], 'user');
        expect((afterAcknowledgement[1] as Map)['role'], 'model');
        expect((afterAcknowledgement[2] as Map)['role'], 'user');
      },
    );
  });
}
