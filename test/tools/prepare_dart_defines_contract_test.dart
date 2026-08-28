import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'prepare script parses env and writes dart defines without logging values',
    () {
      final script = File('tools/prepare_dart_defines.ps1').readAsStringSync();

      expect(script, isNot(contains('GEMINI_API_KEY')));
      expect(script, contains('ConvertTo-Json'));
      expect(script, contains('nanobio_defines.json'));
      expect(script, contains('giá trị bí mật không được in ra terminal'));
      expect(script, isNot(contains(r'Write-Host $values')));
    },
  );

  test('generated defines never contain a provider key', () {
    final definesFile = File('.dart_tool/nanobio_defines.json');
    if (!definesFile.existsSync()) {
      return;
    }

    final values =
        jsonDecode(definesFile.readAsStringSync()) as Map<String, dynamic>;
    expect(values.containsKey('GEMINI_API_KEY'), isFalse);
  });
}
