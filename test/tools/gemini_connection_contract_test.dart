import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'AI preflight uses the trusted backend and never reads a provider key',
    () {
      final script = File(
        'tools/test_gemini_connection.ps1',
      ).readAsStringSync();

      expect(script, isNot(contains('GEMINI_API_KEY')));
      expect(script, contains('/api/v1/ai/generate'));
      expect(script, contains('API_BASE_URL'));
      expect(script, isNot(contains('SUPABASE_')));
      expect(script, contains('NANOBIO_API_ACCESS_TOKEN'));
      expect(script, isNot(contains('GEMINI_MODEL')));
      expect(script, isNot(contains('x-goog-api-key')));
      expect(script, isNot(contains('generativelanguage.googleapis.com')));
    },
  );
}
