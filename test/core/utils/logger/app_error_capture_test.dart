import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/utils/logger/app_error_capture.dart';
import 'package:nano_app/core/utils/logger/terminal_log_sink.dart';

void main() {
  tearDown(() {
    AppErrorCapture.restoreForTesting();
    TerminalLogSink.setTestWriter(null);
  });

  test('captures Flutter framework errors with structured stack context', () {
    final output = <String>[];
    TerminalLogSink.setTestWriter(output.add);
    AppErrorCapture.install();

    FlutterError.reportError(
      FlutterErrorDetails(
        exception: StateError('private framework payload'),
        stack: StackTrace.fromString(
          '#0 Widget.build (package:nano_app/lib/example.dart:12:3)',
        ),
        library: 'widgets library',
        context: ErrorDescription('while building ExampleWidget'),
      ),
    );

    final text = output.join('\n');
    expect(text, contains('[ERROR][UI]'));
    expect(text, contains('FRAMEWORK_ERROR'));
    expect(text, contains('package:nano_app/lib/example.dart:12:3'));
    expect(text, isNot(contains('private framework payload')));
  });
}
