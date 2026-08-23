import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/data/datasources/voice_chat_turn_datasource.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/entities/voice_chat_message.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/voice_chat_exception.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/providers/voice_dependencies.dart';
import 'package:nano_app/app_versions/v1/services/ai/gemini_rest_client.dart';

void main() {
  group('GeminiVoiceChatTurnDatasource', () {
    test(
      'sends the exact sequential Voice request without sampling fields',
      () async {
        String? capturedUrl;
        Map<String, String>? capturedHeaders;
        Map<String, Object?>? capturedBody;
        final datasource = GeminiVoiceChatTurnDatasource(
          environmentReader: _environment({
            'GEMINI_API_KEY': 'local-test-key',
            'GEMINI_CHAT_MODEL': 'gemini-voice-model',
          }),
          postOverride:
              ({required url, required headers, required body}) async {
                capturedUrl = url;
                capturedHeaders = headers;
                capturedBody = body;
                return _success('  Nabi trả lời ngắn gọn.  ');
              },
        );

        final result = await datasource.sendTurn(
          message: '  Tôi nên ngủ lúc nào?  ',
          history: const [
            VoiceChatMessage(role: VoiceChatRole.user, text: 'Xin chào'),
            VoiceChatMessage(role: VoiceChatRole.model, text: 'Nabi chào bạn.'),
          ],
        );

        expect(result, 'Nabi trả lời ngắn gọn.');
        expect(
          capturedUrl,
          '${GeminiRestClient.defaultBaseUrl}/models/'
          'gemini-voice-model:generateContent',
        );
        expect(capturedHeaders?['x-goog-api-key'], 'local-test-key');
        expect(capturedBody, {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': 'Xin chào'},
              ],
            },
            {
              'role': 'model',
              'parts': [
                {'text': 'Nabi chào bạn.'},
              ],
            },
            {
              'role': 'user',
              'parts': [
                {'text': 'Tôi nên ngủ lúc nào?'},
              ],
            },
          ],
          'generationConfig': {
            'maxOutputTokens': 256,
            'thinkingConfig': {'thinkingLevel': 'MINIMAL'},
          },
          'systemInstruction': {
            'parts': [
              {'text': GeminiVoiceChatTurnDatasource.systemInstruction.trim()},
            ],
          },
        });
      },
    );

    test('resolves model as chat, general, then Gemini 3.5 default', () async {
      final cases = <({Map<String, String> environment, String expected})>[
        (
          environment: {
            'GEMINI_API_KEY': 'test-key',
            'GEMINI_CHAT_MODEL': ' chat-model ',
            'GEMINI_MODEL': 'general-model',
          },
          expected: 'chat-model',
        ),
        (
          environment: {
            'GEMINI_API_KEY': 'test-key',
            'GEMINI_MODEL': ' general-model ',
          },
          expected: 'general-model',
        ),
        (
          environment: {'GEMINI_API_KEY': 'test-key'},
          expected: GeminiVoiceChatTurnDatasource.defaultModel,
        ),
      ];

      for (final testCase in cases) {
        String? capturedUrl;
        final datasource = GeminiVoiceChatTurnDatasource(
          environmentReader: _environment(testCase.environment),
          postOverride:
              ({required url, required headers, required body}) async {
                capturedUrl = url;
                return _success('Đã rõ.');
              },
        );

        await datasource.sendTurn(message: 'Xin chào', history: const []);

        expect(
          capturedUrl,
          contains('/models/${testCase.expected}:generateContent'),
        );
      }
    });

    test('uses the configured Gemini base URL', () async {
      String? capturedUrl;
      final datasource = GeminiVoiceChatTurnDatasource(
        environmentReader: _environment({
          'GEMINI_API_KEY': 'test-key',
          'GEMINI_BASE_URL': 'https://example.test/gemini/',
        }),
        postOverride: ({required url, required headers, required body}) async {
          capturedUrl = url;
          return _success('Đã rõ.');
        },
      );

      await datasource.sendTurn(message: 'Xin chào', history: const []);

      expect(
        capturedUrl,
        'https://example.test/gemini/models/'
        '${GeminiVoiceChatTurnDatasource.defaultModel}:generateContent',
      );
    });

    test('accepts input and history entries over 2000 up to 6000', () async {
      Map<String, Object?>? capturedBody;
      final longInput = List<String>.filled(3000, 'u').join();
      final longHistory = List<String>.filled(3000, 'h').join();
      final datasource = _datasourceWithPost(({
        required url,
        required headers,
        required body,
      }) async {
        capturedBody = body;
        return _success('Đã hiểu.');
      });

      expect(
        await datasource.sendTurn(
          message: longInput,
          history: [
            VoiceChatMessage(role: VoiceChatRole.user, text: longHistory),
          ],
        ),
        'Đã hiểu.',
      );

      final contents = capturedBody?['contents'] as List<Object?>;
      expect(
        ((contents.first as Map<String, Object?>)['parts'] as List<Object?>)
            .first,
        {'text': longHistory},
      );
      expect(
        ((contents.last as Map<String, Object?>)['parts'] as List<Object?>)
            .first,
        {'text': longInput},
      );
    });

    test('missing API key fails safely before any request', () async {
      final datasource = GeminiVoiceChatTurnDatasource(
        environmentReader: _environment(const {}),
      );

      await _expectFailure(
        datasource.sendTurn(message: 'Xin chào', history: const []),
        VoiceChatFailure.unavailable,
      );
    });

    for (final status in [408, 429, 500, 503]) {
      test('HTTP $status maps to temporarily unavailable', () async {
        final datasource = _datasourceWithPost(
          ({required url, required headers, required body}) async =>
              GeminiHttpResponse(
                statusCode: status,
                data: {
                  'error': {'status': 'UNAVAILABLE', 'message': 'redacted'},
                },
              ),
        );

        await _expectFailure(
          datasource.sendTurn(message: 'Xin chào', history: const []),
          VoiceChatFailure.temporarilyUnavailable,
        );
      });
    }

    test('network failures and request timeout are temporary', () async {
      final networkDatasource = _datasourceWithPost(({
        required url,
        required headers,
        required body,
      }) async {
        throw const GeminiApiException(
          status: 'network_error',
          message: 'redacted',
        );
      });
      await _expectFailure(
        networkDatasource.sendTurn(message: 'Xin chào', history: const []),
        VoiceChatFailure.temporarilyUnavailable,
      );

      final pending = Completer<GeminiHttpResponse>();
      final timeoutDatasource = _datasourceWithPost(
        ({required url, required headers, required body}) => pending.future,
        timeout: const Duration(milliseconds: 1),
      );
      await _expectFailure(
        timeoutDatasource.sendTurn(message: 'Xin chào', history: const []),
        VoiceChatFailure.temporarilyUnavailable,
      );
    });

    for (final status in [400, 401, 403, 404]) {
      test('key or model HTTP $status maps to unavailable', () async {
        final datasource = _datasourceWithPost(
          ({required url, required headers, required body}) async =>
              GeminiHttpResponse(
                statusCode: status,
                data: {
                  'error': {
                    'status': status == 404 ? 'NOT_FOUND' : 'INVALID_ARGUMENT',
                    'message': 'redacted',
                  },
                },
              ),
        );

        await _expectFailure(
          datasource.sendTurn(message: 'Xin chào', history: const []),
          VoiceChatFailure.unavailable,
        );
      });
    }

    test('empty and oversized Gemini responses are invalid', () async {
      final emptyDatasource = _datasourceWithPost(
        ({required url, required headers, required body}) async =>
            const GeminiHttpResponse(statusCode: 200, data: {'candidates': []}),
      );
      await _expectFailure(
        emptyDatasource.sendTurn(message: 'Xin chào', history: const []),
        VoiceChatFailure.invalidResponse,
      );

      final oversizedDatasource = _datasourceWithPost(
        ({required url, required headers, required body}) async =>
            _success(List<String>.filled(2001, 'a').join()),
      );
      await _expectFailure(
        oversizedDatasource.sendTurn(message: 'Xin chào', history: const []),
        VoiceChatFailure.invalidResponse,
      );
    });

    test('rejects invalid message and history before Gemini', () async {
      var requestCount = 0;
      final datasource = _datasourceWithPost(({
        required url,
        required headers,
        required body,
      }) async {
        requestCount++;
        return _success('Không dùng');
      });

      await _expectFailure(
        datasource.sendTurn(message: '   ', history: const []),
        VoiceChatFailure.invalidRequest,
      );
      await _expectFailure(
        datasource.sendTurn(
          message: List<String>.filled(6001, 'a').join(),
          history: const [],
        ),
        VoiceChatFailure.invalidRequest,
      );
      await _expectFailure(
        datasource.sendTurn(
          message: 'Xin chào',
          history: List<VoiceChatMessage>.filled(
            13,
            const VoiceChatMessage(role: VoiceChatRole.user, text: 'Câu'),
          ),
        ),
        VoiceChatFailure.invalidRequest,
      );
      await _expectFailure(
        datasource.sendTurn(
          message: 'Xin chào',
          history: const [
            VoiceChatMessage(role: VoiceChatRole.model, text: '   '),
          ],
        ),
        VoiceChatFailure.invalidRequest,
      );
      await _expectFailure(
        datasource.sendTurn(
          message: 'Xin chào',
          history: [
            VoiceChatMessage(
              role: VoiceChatRole.user,
              text: List<String>.filled(6001, 'a').join(),
            ),
          ],
        ),
        VoiceChatFailure.invalidRequest,
      );
      expect(requestCount, 0);
    });
  });

  test('Voice provider wires the direct Gemini datasource', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(voiceChatTurnDatasourceProvider),
      isA<GeminiVoiceChatTurnDatasource>(),
    );
  });
}

GeminiVoiceChatTurnDatasource _datasourceWithPost(
  GeminiHttpPost post, {
  Duration timeout = const Duration(seconds: 30),
}) {
  return GeminiVoiceChatTurnDatasource(
    environmentReader: _environment({'GEMINI_API_KEY': 'test-key'}),
    postOverride: post,
    requestTimeout: timeout,
  );
}

VoiceEnvironmentReader _environment(Map<String, String> values) {
  return (key) => values[key];
}

GeminiHttpResponse _success(String text) {
  return GeminiHttpResponse(
    statusCode: 200,
    data: {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        },
      ],
    },
  );
}

Future<void> _expectFailure(
  Future<String> future,
  VoiceChatFailure failure,
) async {
  await expectLater(
    future,
    throwsA(
      isA<VoiceChatException>().having(
        (error) => error.failure,
        'failure',
        failure,
      ),
    ),
  );
}
