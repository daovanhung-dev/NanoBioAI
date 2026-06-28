import 'package:sqflite/sqflite.dart';

import 'sync_outbox_schema.dart';

/// Guards SQLite triggers while cloud data is being applied locally.
///
/// Without this guard, a cloud pull would enqueue the same rows again and
/// create a pull -> push loop. The state is persisted inside the same SQLite
/// transaction as the replacement so process restarts cannot leave a partial
/// local apply unnoticed.
class SyncRuntimeState {
  SyncRuntimeState._();

  static Future<void> setApplyingCloud(DatabaseExecutor executor, bool value) {
    return executor.insert(
      SyncOutboxSchema.runtimeStateTable,
      {
        'key': SyncOutboxSchema.applyingCloudKey,
        'value': value ? '1' : '0',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
