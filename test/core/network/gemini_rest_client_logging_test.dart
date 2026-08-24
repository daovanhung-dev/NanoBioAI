import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/services/ai/gemini_rest_client.dart';
import 'package:nano_app/core/utils/logger/terminal_log_sink.dart';

void main() {
  tearDown(() => TerminalLogSink.setTestWriter(null));

  test('Gemini private Dio uses structured logging without leaking API key', () async {
    final output = <String>[];
    TerminalLogSink.setTestWriter(output.add);

    final dio = Dio()..httpClientAdapter = _GeminiAdapter();
    final client = GeminiRestClient(apiKey: 'private-gemini-key', dio: dio);

    final text = await client.generateText(
      model: 'gemini-test',
      contents: const [GeminiContent.user('private health prompt')],
      generationConfig: const GeminiGenerationConfig(maxOutputTokens: 32),
    );

    expect(text, 'ok');
    final logs = output.join('\n');
    expect(logs, contains('[HTTP][Gemini][REQUEST]'));
    expect(logs, contains('[HTTP][Gemini][RESPONSE]'));
    expect(logs, contains('statusCode=200'));
    expect(logs, isNot(contains('private-gemini-key')));
    expect(logs, isNot(contains('private health prompt')));
  });
}

class _GeminiAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'ok'},
              ],
            },
          },
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
