import 'package:sqflite/sqflite.dart';

import '../tables/schedule_health_checkin_outbox_table.dart';

class MigrationV19 {
  const MigrationV19._();

  static Future<void> run(Database db) => ensureSchema(db);

  static Future<void> ensureSchema(DatabaseExecutor db) async {
    await db.execute(ScheduleHealthCheckInOutboxTable.createTable);
    await db.execute(ScheduleHealthCheckInOutboxTable.createPendingIndex);
    await db.execute(ScheduleHealthCheckInOutboxTable.createScheduleIndex);
  }
}
