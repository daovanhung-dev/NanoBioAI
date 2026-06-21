import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cloud sync source contract', () {
    test('remote datasource remaps local IDs and source_id references', () {
      final source = File(
        'lib/app_versions/v2/features/cloud_sync/data/datasources/'
        'supabase_user_data_sync_remote_datasource.dart',
      ).readAsStringSync();

      expect(source, contains('_buildCloudIdMap'));
      expect(source, contains("column == 'source_id'"));
      expect(source, contains('idMap[sourceId]'));
      expect(source, contains('_newUuidV4'));
    });

    test(
      'sync table list excludes catalog, payment, sale, and family tables',
      () {
        final source = File(
          'lib/app_versions/v2/features/cloud_sync/data/datasources/'
          'user_data_sync_tables.dart',
        ).readAsStringSync();

        expect(source, contains("'meal_plans'"));
        expect(source, contains("'daily_health_tasks'"));
        expect(source, contains("'lifestyle_schedule_items'"));
        expect(source, contains("'notifications'"));
        expect(source, isNot(contains('meal_catalog')));
        expect(source, isNot(contains('payment')));
        expect(source, isNot(contains('sale')));
        expect(source, isNot(contains('family')));
      },
    );
  });
}
