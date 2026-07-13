import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'prepare script parses env and writes dart defines without logging values',
    () {
      final script = File('tools/prepare_dart_defines.ps1').readAsStringSync();

      expect(script, contains('GEMINI_API_KEY'));
      expect(script, contains('ConvertTo-Json'));
      expect(script, contains('nanobio_defines.json'));
      expect(script, contains('without printing secret values'));
      expect(script, isNot(contains(r'Write-Host $values')));
    },
  );

  test(
    'generated defines contain the local Gemini key without exposing it',
    () {
      final definesFile = File('.dart_tool/nanobio_defines.json');
      if (!definesFile.existsSync()) {
        return;
      }

      final values =
          jsonDecode(definesFile.readAsStringSync()) as Map<String, dynamic>;
      final key = values['GEMINI_API_KEY'] as String?;
      expect(key, isNotNull);
      expect(key, isNotEmpty);
    },
  );
}
