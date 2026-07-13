import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/data/datasources/user_data_sync_tables.dart';
import 'package:nano_app/core/storage/localdb/sync/sync_outbox_schema.dart';

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
        const localTables = UserDataSyncTables.localUserOwnedTables;
        const pullTables = UserDataSyncTables.cloudPullTables;
        const cloudTables = UserDataSyncTables.cloudCollectionTables;
        final allTableNames = {
          ...localTables,
          ...cloudTables,
          ...UserDataSyncTables.localColumnsByTable.keys,
          ...UserDataSyncTables.cloudColumnsByTable.keys,
        };

        expect(localTables, contains('meal_plans'));
        expect(localTables, contains('daily_health_tasks'));
        expect(localTables, contains('lifestyle_schedule_items'));
        expect(localTables, contains('health_score_ledgers'));
        expect(localTables, isNot(contains('wellness_point_ledgers')));
        expect(pullTables, contains('wellness_point_ledgers'));
        expect(
          SyncOutboxSchema.serverOwnedReadOnlyTables,
          contains('wellness_point_ledgers'),
        );
        expect(cloudTables, contains('health_score_ledgers'));
        expect(cloudTables, contains('wellness_point_ledgers'));
        expect(localTables, contains('notifications'));
        expect(localTables, contains('personal_schedule_ai_requests'));
        expect(cloudTables, contains('personal_schedule_ai_requests'));
        expect(
          SyncOutboxSchema.genericIdUserOwnedTables,
          isNot(contains('personal_schedule_ai_requests')),
        );
        expect(
          UserDataSyncTables
              .localColumnsByTable['personal_schedule_ai_requests'],
          contains('request_id'),
        );
        expect(
          UserDataSyncTables
              .cloudColumnsByTable['personal_schedule_ai_requests'],
          contains('request_id'),
        );
        expect(
          UserDataSyncTables.localColumnsByTable['lifestyle_schedule_items'],
          contains('completion_proof_path'),
        );
        expect(
          UserDataSyncTables.cloudColumnsByTable['lifestyle_schedule_items'],
          isNot(contains('completion_proof_path')),
        );
        expect(allTableNames, isNot(contains('meal_catalog')));
        expect(allTableNames, isNot(contains('payment_events')));
        expect(allTableNames, isNot(contains('sale_profiles')));
        expect(allTableNames, isNot(contains('family_groups')));
      },
    );

    test(
      'remote pull includes server-owned ledgers but snapshot push does not',
      () {
        final source = File(
          'lib/app_versions/v2/features/cloud_sync/data/datasources/'
          'supabase_user_data_sync_remote_datasource.dart',
        ).readAsStringSync();

        expect(
          source,
          contains('for (final table in UserDataSyncTables.cloudPullTables)'),
        );
        expect(
          RegExp(
            r'_cloudSnapshotPayload[\s\S]*?for \(final table in '
            r'UserDataSyncTables\.localUserOwnedTables\)',
          ).hasMatch(source),
          isTrue,
        );
      },
    );
  });
}
