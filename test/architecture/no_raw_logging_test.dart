import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production Dart code does not bypass AppLogger', () async {
    final violations = <String>[];
    final lib = Directory('lib');
    expect(lib.existsSync(), isTrue, reason: 'Run this test from repository root.');

    await for (final entity in lib.list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      if (normalized.endsWith('/core/utils/logger/terminal_log_sink.dart')) {
        continue;
      }

      final lines = await entity.readAsLines();
      var inBlockComment = false;
      for (var index = 0; index < lines.length; index++) {
        final raw = lines[index];
        final trimmed = raw.trim();
        if (trimmed.startsWith('/*')) inBlockComment = true;
        if (inBlockComment) {
          if (trimmed.contains('*/')) inBlockComment = false;
          continue;
        }
        if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;

        final hasRawPrint = RegExp(r'(^|[^A-Za-z0-9_])print\s*\(').hasMatch(raw);
        final hasDebugPrint = RegExp(r'\bdebugPrint\s*\(').hasMatch(raw);
        final hasDeveloperLog = RegExp(r'\bdeveloper\.log\s*\(').hasMatch(raw);
        if (hasRawPrint || hasDebugPrint || hasDeveloperLog) {
          violations.add('$normalized:${index + 1}: $trimmed');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Route production logs through AppLogger instead:\n${violations.join('\n')}',
    );
  });
}
