import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Food Scan uses the dedicated Edge Function for both AI operations', () {
    final datasource = File(
      'lib/app_versions/v3/features/food_scan/data/datasources/food_scan_ai_datasource.dart',
    ).readAsStringSync();
    final backend = File(
      'lib/app_versions/v1/services/ai/nabi_ai_backend_client.dart',
    ).readAsStringSync();
    final handler = File(
      'supabase/functions/food-scan-analyze/handler.ts',
    ).readAsStringSync();
    final index = File(
      'supabase/functions/food-scan-analyze/index.ts',
    ).readAsStringSync();
    final config = File('supabase/config.toml').readAsStringSync();

    expect(datasource, contains("functionName: 'food-scan-analyze'"));
    expect(datasource, contains("operation: 'vision'"));
    expect(datasource, contains("operation: 'health'"));
    expect(backend, contains("if (operation != null) 'operation': operation"));
    expect(config, contains('[functions.food-scan-analyze]'));
    expect(config, contains('[functions.food-scan-analyze]\nverify_jwt = true'));
    expect(index, contains('effective_user_access'));
    expect(handler, contains('PLUS_REQUIRED'));
  });
}
