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
      expect(script, contains('nabi-ai-generate'));
      expect(script, contains('SUPABASE_ANON_KEY'));
      expect(script, contains('GEMINI_MODEL'));
      expect(script, isNot(contains('x-goog-api-key')));
      expect(script, isNot(contains('generativelanguage.googleapis.com')));
    },
  );
}
