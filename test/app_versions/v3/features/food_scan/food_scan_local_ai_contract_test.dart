import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Food Scan uses local vision and text inference only', () {
    final datasource = File(
      'lib/app_versions/v3/features/food_scan/data/datasources/food_scan_ai_datasource.dart',
    ).readAsStringSync();
    final runtime = File(
      'lib/core/ai_local/local_ai_runtime_service_native.dart',
    ).readAsStringSync();

    expect(datasource, contains("_client(operation: 'vision')"));
    expect(datasource, contains("_client(operation: 'health')"));
    expect(
      datasource,
      contains('return LocalAiTextClient(operation: operation);'),
    );
    expect(datasource, contains('AiImageAttachment'));
    expect(runtime, contains('localAiVisionAssets'));
    expect(runtime, contains('_downloadAssets('));
    expect(datasource, isNot(contains('NabiAiBackendClient')));
    expect(datasource, isNot(contains('food-scan-analyze')));
  });
}
