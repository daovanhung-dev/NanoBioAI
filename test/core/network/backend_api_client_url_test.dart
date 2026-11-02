import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nano_app/core/network/backend_api_client.dart';

void main() {
  test('resolves versioned API paths against the production origin', () async {
    Uri? capturedUri;
    final client = BackendApiClient(
      baseUrl: defaultBackendApiBaseUrl,
      sessionStore: _MemorySessionStore(),
      httpClient: MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'ok': true},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.close);

    await client.requestResponse(
      'GET',
      '/api/v1/auth/session',
      authenticated: false,
    );

    expect(capturedUri?.origin, 'https://nanobio.s2w.click');
    expect(capturedUri?.path, '/api/v1/auth/session');
  });

  test(
    'rejects an API-prefixed base URL to prevent duplicate version paths',
    () {
      expect(
        () => BackendApiClient(baseUrl: 'https://nanobio.s2w.click/api/v1'),
        throwsArgumentError,
      );
    },
  );
}

class _MemorySessionStore implements BackendSessionStore {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String value) async {}

  @override
  Future<void> clear() async {}
}
