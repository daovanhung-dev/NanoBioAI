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
      expect(
        capturedUrl,
        endsWith('/models/gemini-3.5-flash:generateContent'),
      );
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
  });
}
