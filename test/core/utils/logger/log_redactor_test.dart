import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/utils/logger/log_redactor.dart';

void main() {
  test('recursively redacts sensitive metadata', () {
    final sanitized = LogRedactor.metadata({
      'status': 'ok',
      'count': 3,
      'auth': {
        'access_token': 'secret-token',
        'nested': {'password': '123456'},
      },
      'healthScore': 99,
    });

    final text = sanitized.toString();
    expect(text, contains('status: ok'));
    expect(text, contains('count: 3'));
    expect(text, isNot(contains('secret-token')));
    expect(text, isNot(contains('123456')));
    expect(text, isNot(contains('99')));
  });

  test('preserves allowlisted local inference telemetry counters', () {
    final sanitized = LogRedactor.metadata({
      'inputTokens': 1429,
      'outputTokens': 73,
      'contextSize': 2048,
      'inferenceThreads': 3,
      'streamBatchTokenThreshold': 8,
      'accessToken': 'must-not-appear',
    });

    expect(sanitized['inputTokens'], 1429);
    expect(sanitized['outputTokens'], 73);
    expect(sanitized['contextSize'], 2048);
    expect(sanitized['inferenceThreads'], 3);
    expect(sanitized['streamBatchTokenThreshold'], 8);
    expect(sanitized['accessToken'], '[REDACTED]');
  });

  test('URI logging exposes query names but never query values', () {
    final safe = LogRedactor.sanitizeUri(
      Uri.parse('https://example.com/users/123456?token=secret&q=hello'),
    );

    expect(safe, contains('/users/[REDACTED_ID]'));
    expect(safe, contains('keys=q,token'));
    expect(safe, isNot(contains('secret')));
    expect(safe, isNot(contains('hello')));
  });
}
