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
      expect(client, contains('jsonDecode'));
      expect(client, contains("'OUTPUT_TRUNCATED'"));
      expect(client, isNot(contains('GEMINI_API_KEY')));
      expect(backend, contains('requiredEnvironment("GEMINI_API_KEY")'));
      expect(backend, contains('generativelanguage.googleapis.com'));
    },
  );

  test('does not define an app-owned max output token at production call sites', () {
    final productionFiles = [
      'lib/app_versions/v1/services/ai/ai_chat_service.dart',
      'lib/app_versions/v1/services/ai/ai_service.dart',
      'lib/app_versions/v1/services/ai/nabi_care_ai_gateway.dart',
      'lib/app_versions/v1/features/body_metrics/application/body_metrics_ai_service.dart',
      'lib/app_versions/v1/features/nutrition/application/nutrition_ai_service.dart',
      'lib/app_versions/v1/features/sleep_tracking/data/services/sleep_analysis_ai_service.dart',
      'lib/app_versions/v1/features/ai_voice/data/datasources/voice_chat_turn_datasource.dart',
      'lib/app_versions/v3/features/food_scan/data/datasources/food_scan_ai_datasource.dart',
    ];

    for (final path in productionFiles) {
      expect(File(path).readAsStringSync(), isNot(contains('maxOutputTokens:')));
    }
  });
}
