import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/utils/logger/app_log_category.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/core/utils/logger/terminal_log_sink.dart';

void main() {
  tearDown(() => TerminalLogSink.setTestWriter(null));

  test('logger redacts secrets/PII but preserves useful stack location', () {
    final output = <String>[];
    TerminalLogSink.setTestWriter(output.add);

    AppLogger.info('TEST', 'userId=private-user-123');
    AppLogger.form('TEST', 'email', 'secret@example.com');
    AppLogger.captureError(
      category: AppLogCategory.logic,
      scope: 'PrivacyTest',
      operation: 'FAIL',
      message: 'request failed token=super-secret-token',
      error: StateError('secret-exception-payload'),
      stackTrace: StackTrace.fromString(
        '#0 PrivacyTest.run (package:nano_app/test/privacy_test.dart:10:2)',
      ),
    );
    AppLogger.summary('TEST', 'SUMMARY', {
      'email': 'secret@example.com',
      'Health Score': 91,
      'Goals Count': 3,
      'Status': 'Failed',
    });

    final text = output.join('\n');
    for (final forbidden in const [
      'private-user-123',
      'secret@example.com',
      'super-secret-token',
      'secret-exception-payload',
      'Health Score=91',
    ]) {
      expect(text, isNot(contains(forbidden)));
    }
    expect(text, contains('Goals Count=3'));
    expect(text, contains('errorType=StateError'));
    expect(text, contains('package:nano_app/test/privacy_test.dart:10:2'));
  });
}
