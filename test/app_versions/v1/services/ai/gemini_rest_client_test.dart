import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/services/ai/gemini_rest_client.dart';

void main() {
  group('GeminiRestClient', () {
    test('gửi API key bằng header và trích xuất nội dung trả về', () async {
      late String capturedUrl;
      late Map<String, String> capturedHeaders;
      late Map<String, Object?> capturedBody;

      final client = GeminiRestClient(
        apiKey: 'test-api-key-with-safe-length',
        post:
            ({
              required String url,
              required Map<String, String> headers,
              required Map<String, Object?> body,
            }) async {
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
                          {'text': 'Bạn nên giữ giờ ngủ ổn định mỗi tối.'},
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
        contents: const [GeminiContent.user('Làm sao để ngủ sâu hơn?')],
        generationConfig: const GeminiGenerationConfig(
          maxOutputTokens: 128,
          temperature: 0.2,
          topP: 0.8,
        ),
      );

      expect(result, 'Bạn nên giữ giờ ngủ ổn định mỗi tối.');
      expect(capturedUrl, endsWith('/models/gemini-3.5-flash:generateContent'));
      expect(
        capturedHeaders['x-goog-api-key'],
        'test-api-key-with-safe-length',
      );
      expect(capturedBody['contents'], isA<List<Object?>>());
    });

    test('giữ nguyên mã và trạng thái lỗi từ Gemini', () async {
      final client = GeminiRestClient(
        apiKey: 'test-api-key-with-safe-length',
        post:
            ({
              required String url,
              required Map<String, String> headers,
              required Map<String, Object?> body,
            }) async {
              return const GeminiHttpResponse(
                statusCode: 404,
                data: {
                  'error': {
                    'status': 'NOT_FOUND',
                    'message': 'Requested model was not found.',
                  },
                },
              );
            },
      );

      await expectLater(
        client.generateText(
          model: 'retired-model',
          contents: const [GeminiContent.user('Xin chào')],
          generationConfig: const GeminiGenerationConfig(
            maxOutputTokens: 64,
            temperature: 0.2,
            topP: 0.8,
          ),
        ),
        throwsA(
          isA<GeminiApiException>()
              .having((error) => error.statusCode, 'statusCode', 404)
              .having((error) => error.status, 'status', 'NOT_FOUND')
              .having(
                (error) => error.isModelUnavailable,
                'isModelUnavailable',
                isTrue,
              ),
        ),
      );
    });

    test('coi lỗi kết nối là lỗi có thể thử lại', () {
      const error = GeminiApiException(
        status: 'network_error',
        message: 'Could not connect to Gemini.',
      );

      expect(error.isNetworkFailure, isTrue);
      expect(error.isTransient, isTrue);
    });

    test('hỗ trợ Gemini 3 thinking tối thiểu và bỏ sampling tùy chọn', () {
      const config = GeminiGenerationConfig(
        candidateCount: null,
        maxOutputTokens: 256,
        thinkingLevel: 'MINIMAL',
      );

      expect(config.toJson(), {
        'maxOutputTokens': 256,
        'thinkingConfig': {'thinkingLevel': 'MINIMAL'},
      });
    });

    test('không đưa phần suy luận nội bộ vào văn bản trả về', () async {
      final client = GeminiRestClient(
        apiKey: 'test-api-key-with-safe-length',
        post:
            ({
              required String url,
              required Map<String, String> headers,
              required Map<String, Object?> body,
            }) async {
              return const GeminiHttpResponse(
                statusCode: 200,
                data: {
                  'candidates': [
                    {
                      'content': {
                        'parts': [
                          {'thought': true, 'text': 'Suy luận nội bộ'},
                          {'text': 'Câu trả lời dành cho người dùng.'},
                        ],
                      },
                    },
                  ],
                },
              );
            },
      );

      final result = await client.generateText(
        model: 'gemini-3.5-flash',
        contents: const [GeminiContent.user('Xin chào')],
        generationConfig: const GeminiGenerationConfig(
          candidateCount: null,
          maxOutputTokens: 256,
          thinkingLevel: 'MINIMAL',
        ),
      );

      expect(result, 'Câu trả lời dành cho người dùng.');
    });

    test('omits maxOutputTokens when no app-owned cap is provided', () {
      const config = GeminiGenerationConfig(
        candidateCount: null,
        temperature: 0.2,
      );

      expect(config.toJson(), {'temperature': 0.2});
    });

    test('rejects a response with text followed by MAX_TOKENS', () async {
      final client = GeminiRestClient(
        apiKey: 'test-api-key-with-safe-length',
        post: ({required url, required headers, required body}) async {
          return const GeminiHttpResponse(
            statusCode: 200,
            data: {
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Phần trả lời bị cắt.'},
                    ],
                  },
                  'finishReason': 'MAX_TOKENS',
                },
              ],
            },
          );
        },
      );

      await expectLater(
        client.generateText(
          model: 'gemini-3.5-flash',
          contents: const [GeminiContent.user('Xin chào')],
          generationConfig: const GeminiGenerationConfig(),
        ),
        throwsA(
          isA<GeminiApiException>()
              .having((error) => error.isOutputTruncated, 'truncated', isTrue)
              .having((error) => error.isTransient, 'transient', isFalse),
        ),
      );
    });

    test('accepts a JSON string response and preserves all text parts', () async {
      final client = GeminiRestClient(
        apiKey: 'test-api-key-with-safe-length',
        post: ({required url, required headers, required body}) async {
          return GeminiHttpResponse(
            statusCode: 200,
            data: jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Phần đầu.'},
                      {'text': 'Phần cuối.'},
                    ],
                  },
                },
              ],
            }),
          );
        },
      );

      expect(
        await client.generateText(
          model: 'gemini-3.5-flash',
          contents: const [GeminiContent.user('Xin chào')],
          generationConfig: const GeminiGenerationConfig(),
        ),
        'Phần đầu.\nPhần cuối.',
      );
    });
  });
}
