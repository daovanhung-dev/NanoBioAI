import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'production AI transport invokes Supabase and never carries Gemini key',
    () {
      final client = File(
        'lib/app_versions/v1/services/ai/nabi_ai_backend_client.dart',
      ).readAsStringSync();
      final backend = File(
        'supabase/functions/nabi-ai-generate/index.ts',
      ).readAsStringSync();

      expect(client, contains("'nabi-ai-generate'"));
      expect(client, contains('functions.invoke'));
      expect(client, isNot(contains('GEMINI_API_KEY')));
      expect(backend, contains('requiredEnvironment("GEMINI_API_KEY")'));
      expect(backend, contains('generativelanguage.googleapis.com'));
    },
  );
}
