import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/tables/wellness_rewards_cache_tables.dart';
import 'package:sqflite/sqflite.dart';

import 'schedule_reward_online_gateway.dart';

abstract class ScheduleRewardEligibilityProjectionStore {
  Future<void> markRegistered({
    required String userId,
    required String requestId,
    required List<ScheduleRewardEligibilityItem> items,
  });
}

class SqliteScheduleRewardEligibilityProjectionStore
    implements ScheduleRewardEligibilityProjectionStore {
  final Database? databaseOverride;

  const SqliteScheduleRewardEligibilityProjectionStore({this.databaseOverride});

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  @override
  Future<void> markRegistered({
    required String userId,
    required String requestId,
    required List<ScheduleRewardEligibilityItem> items,
  }) async {
    if (userId.trim().isEmpty || requestId.trim().isEmpty || items.isEmpty) {
      return;
    }
    final db = await _db();
    final syncedAt = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final item in items) {
        final windowStart = _vietnamIso(item.scheduleDate, item.startTime);
        batch.insert(
          ScheduleRewardEligibilityCacheTable.tableName,
          {
            'schedule_item_id': item.scheduleItemId,
            'user_id': userId,
            'eligibility_id': null,
            'request_id': requestId,
            'status': 'registered',
            'window_start': windowStart,
            'window_end': windowStart == null
                ? null
                : DateTime.parse(
                    windowStart,
                  ).add(const Duration(minutes: 30)).toIso8601String(),
            'synced_at': syncedAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  String? _vietnamIso(String scheduleDate, String startTime) {
    final date = scheduleDate.trim();
    final time = startTime.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ||
        !RegExp(r'^\d{2}:\d{2}(?::\d{2}(?:\.\d{1,6})?)?$').hasMatch(time)) {
      return null;
    }
    final normalizedTime = time.length == 5 ? '$time:00' : time;
    final candidate = '${date}T$normalizedTime+07:00';
    return DateTime.tryParse(candidate)?.toIso8601String();
  }
}
