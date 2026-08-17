import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';

void main() {
  test('logger does not emit raw sensitive values or stack traces', () async {
    final output = await _captureDebugPrint(() async {
      AppLogger.info('TEST', 'userId=private-user-123');
      AppLogger.form('TEST', 'email', 'secret@example.com');
      AppLogger.error(
        'TEST',
        'request failed',
        StateError('secret-exception-payload'),
        StackTrace.fromString('secret-stack-trace'),
      );
      AppLogger.summary('TEST', 'SUMMARY', {
        'email': 'secret@example.com',
        'Health Score': 91,
        'Goals Count': 3,
        'Status': 'Failed',
      });
    });

    final text = output.join('\n');
    for (final forbidden in const [
      'private-user-123',
      'secret@example.com',
      'secret-exception-payload',
      'secret-stack-trace',
      '91',
    ]) {
      expect(text, isNot(contains(forbidden)));
    }
    expect(text, contains('Goals Count: 3'));
    expect(text, contains('ErrorType: StateError'));
  });
}

Future<List<String>> _captureDebugPrint(Future<void> Function() action) async {
  final messages = <String>[];
  final previousDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) messages.add(message);
  };
  try {
    await action();
  } finally {
    debugPrint = previousDebugPrint;
  }
  return messages;
}
