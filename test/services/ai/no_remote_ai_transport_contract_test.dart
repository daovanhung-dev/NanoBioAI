import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production AI services have no remote AI transport route', () {
    const productionFiles = [
      'lib/app_versions/v1/services/ai/ai_service.dart',
      'lib/app_versions/v1/services/ai/ai_chat_service.dart',
      'lib/app_versions/v1/services/ai/nabi_care_ai_gateway.dart',
      'lib/app_versions/v1/features/body_metrics/application/body_metrics_ai_service.dart',
      'lib/app_versions/v1/features/nutrition/application/nutrition_ai_service.dart',
      'lib/app_versions/v1/features/sleep_tracking/data/services/sleep_analysis_ai_service.dart',
      'lib/app_versions/v1/features/ai_voice/data/datasources/voice_chat_turn_datasource.dart',
      'lib/app_versions/v3/features/food_scan/data/datasources/food_scan_ai_datasource.dart',
    ];

    for (final path in productionFiles) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('NabiAiBackendClient')), reason: path);
      expect(source, isNot(contains('nabi-ai-generate')), reason: path);
      expect(source, isNot(contains('food-scan-analyze')), reason: path);
    }

    final appEnv = File('lib/core/config/app_env.dart').readAsStringSync();
    expect(appEnv, isNot(contains("'GEMINI_")));
    final dartDefineScript = File(
      'tools/prepare_dart_defines.ps1',
    ).readAsStringSync();
    expect(dartDefineScript, isNot(contains('GEMINI_')));
    expect(
      File(
        'lib/app_versions/v1/services/ai/gemini_rest_client.dart',
      ).existsSync(),
      isFalse,
    );
    expect(
      File(
        'lib/app_versions/v1/services/ai/nabi_ai_backend_client.dart',
      ).existsSync(),
      isFalse,
    );
  });

  test('user quota gateway remains the only schedule backend dependency', () {
    final service = File(
      'lib/app_versions/v1/features/fitness_training/application/fitness_training_service.dart',
    ).readAsStringSync();
    expect(service, contains('TrustedBackendPersonalScheduleQuotaGateway'));
    expect(service, contains('checkGeneration('));
    expect(service, contains('commitGeneration('));
  });
}
