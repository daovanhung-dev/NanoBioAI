import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_text_client.dart';
import 'package:nano_app/core/network/backend_ai_text_client.dart';
import 'package:nano_app/core/network/backend_api_client.dart';

void main() {
  late BackendApiClient api;
  late List<http.Request> requests;

  setUp(() async {
    requests = [];
    api = BackendApiClient(
      baseUrl: 'https://api.example.test',
      sessionStore: _MemorySessionStore(),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/stream')) {
          return http.Response.bytes(
            utf8.encode(
              '{"type":"delta","data":{"text":"Mình nghe"}}\n'
              '{"type":"complete","data":{"model":"qwen3:4b-instruct"}}\n',
            ),
            200,
            headers: {'content-type': 'application/x-ndjson'},
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'businessCode': 'AI_GENERATED',
            'data': {'text': 'Mình nghe bạn.'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    await api.establishSession({
      'access_token': 'test-access-token',
      'refresh_token': 'test-refresh-token',
      'expires_in': 900,
      'user': {
        'id': 'user-1',
        'roles': ['user'],
      },
    });
  });

  tearDown(() => api.close());

  test(
    'sends authenticated generation and JSON settings to the backend',
    () async {
      final client = BackendAiTextClient(clientOverride: api);
      final text = await client.generateText(
        model: BackendAiTextClient.modelId,
        messages: const [AiMessage.user('Tạo gợi ý.')],
        generationConfig: const AiGenerationConfig(
          responseFormat: AiResponseFormat.json,
          responseJsonSchema: {'type': 'object'},
          maxOutputTokens: 128,
        ),
        systemInstruction: 'Giữ câu trả lời ngắn.',
      );

      expect(text, 'Mình nghe bạn.');
      expect(requests.single.url.path, '/api/v1/ai/generate');
      expect(
        requests.single.headers['x-trace-id'],
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
            r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(
        requests.single.headers['authorization'],
        'Bearer test-access-token',
      );
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body['response_format'], 'json');
      expect(body['system_instruction'], 'Giữ câu trả lời ngắn.');
      expect(body['max_output_tokens'], 128);
      expect(body['messages'], [
        {'role': 'user', 'content': 'Tạo gợi ý.'},
      ]);
    },
  );

  test('sends image requests through the Food Scan vision endpoint', () async {
    final client = BackendAiTextClient(clientOverride: api);
    final text = await client.generateText(
      model: BackendAiTextClient.modelId,
      messages: [
        AiMessage.user(
          'Nhận diện thực phẩm.',
          images: [
            AiImageAttachment(
              bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0x01]),
              mimeType: 'image/jpeg',
            ),
          ],
        ),
      ],
      generationConfig: const AiGenerationConfig(
        responseFormat: AiResponseFormat.json,
      ),
    );

    expect(text, 'Mình nghe bạn.');
    expect(requests.single.url.path, '/api/v1/food/scan/analyze');
    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(body['mime_type'], 'image/jpeg');
    expect(body['image_base64'], base64Encode([0xff, 0xd8, 0xff, 0x01]));
  });

  test('parses streamed deltas from the backend', () async {
    final client = BackendAiTextClient(clientOverride: api);
    final deltas = await client
        .streamText(
          model: BackendAiTextClient.modelId,
          messages: const [AiMessage.user('Chào Nabi.')],
          generationConfig: const AiGenerationConfig(),
        )
        .toList();

    expect(deltas, ['Mình nghe']);
    expect(requests.single.url.path, '/api/v1/ai/generate/stream');
    expect(
      requests.single.headers['x-trace-id'],
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
          r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test(
    'preserves a backend rate-limit code and status for diagnostics',
    () async {
      final rateLimitedApi = BackendApiClient(
        baseUrl: 'https://api.example.test',
        sessionStore: _MemorySessionStore(),
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({
              'success': false,
              'businessCode': 'RATE_LIMITED',
              'message': 'Bạn gửi yêu cầu hơi nhanh.',
              'data': null,
              'traceId': 'server-trace-1',
            }),
            429,
            headers: {
              'content-type': 'application/json; charset=utf-8',
              'x-trace-id': 'server-trace-1',
            },
          );
        }),
      );
      addTearDown(rateLimitedApi.close);
      await rateLimitedApi.establishSession({
        'access_token': 'test-access-token',
        'refresh_token': 'test-refresh-token',
        'expires_in': 900,
        'user': {'id': 'user-1'},
      });

      final client = BackendAiTextClient(clientOverride: rateLimitedApi);
      await expectLater(
        client.generateText(
          model: BackendAiTextClient.modelId,
          messages: const [AiMessage.user('Tạo lịch.')],
          generationConfig: const AiGenerationConfig(),
        ),
        throwsA(
          isA<BackendAiInferenceException>()
              .having((error) => error.statusCode, 'statusCode', 429)
              .having(
                (error) => error.backendErrorCode,
                'businessCode',
                'RATE_LIMITED',
              )
              .having((error) => error.status, 'status', 'rate_limit_exceeded'),
        ),
      );
      expect(requests.single.headers['x-trace-id'], isNotEmpty);
    },
  );

  test('maps a client transport failure to a safe network error', () async {
    final disconnectedApi = BackendApiClient(
      baseUrl: 'https://api.example.test',
      sessionStore: _MemorySessionStore(),
      httpClient: MockClient(
        (_) async => throw http.ClientException('private transport detail'),
      ),
    );
    addTearDown(disconnectedApi.close);
    await disconnectedApi.establishSession({
      'access_token': 'test-access-token',
      'refresh_token': 'test-refresh-token',
      'expires_in': 900,
      'user': {'id': 'user-1'},
    });

    final client = BackendAiTextClient(clientOverride: disconnectedApi);
    await expectLater(
      client.generateText(
        model: BackendAiTextClient.modelId,
        messages: const [AiMessage.user('Tạo lịch.')],
        generationConfig: const AiGenerationConfig(),
      ),
      throwsA(
        isA<BackendAiInferenceException>()
            .having((error) => error.statusCode, 'statusCode', 0)
            .having(
              (error) => error.backendErrorCode,
              'businessCode',
              'NETWORK_UNAVAILABLE',
            )
            .having((error) => error.status, 'status', 'network_error')
            .having(
              (error) => error.message,
              'safeMessage',
              contains('Chưa kết nối được'),
            ),
      ),
    );
  });

  test(
    'requires a backend session and never sends an anonymous AI request',
    () async {
      final anonymousApi = BackendApiClient(
        baseUrl: 'https://api.example.test',
        sessionStore: _MemorySessionStore(),
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response('{}', 401);
        }),
      );
      addTearDown(anonymousApi.close);
      final client = BackendAiTextClient(clientOverride: anonymousApi);

      await expectLater(
        client.generateText(
          model: BackendAiTextClient.modelId,
          messages: const [AiMessage.user('Tạo lịch.')],
          generationConfig: const AiGenerationConfig(),
        ),
        throwsA(
          isA<AiInferenceException>()
              .having((error) => error.isAuthenticationFailure, 'auth', isTrue)
              .having((error) => error.statusCode, 'statusCode', 401),
        ),
      );
      await expectLater(
        client
            .streamText(
              model: BackendAiTextClient.modelId,
              messages: const [AiMessage.user('Chào Nabi.')],
              generationConfig: const AiGenerationConfig(),
            )
            .toList(),
        throwsA(isA<AiInferenceException>()),
      );

      expect(requests, isEmpty);
    },
  );
}

class _MemorySessionStore implements BackendSessionStore {
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}
