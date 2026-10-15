import 'package:nano_app/core/storage/localdb/tables/medication_reminders_table.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV34 {
  const MigrationV34._();

  static Future<void> run(DatabaseExecutor db) async {
    await db.execute(MedicationRemindersTable.createTable);
    await db.execute(MedicationRemindersTable.createUserIndex);
  }

  static Future<void> ensureSchema(DatabaseExecutor db) => run(db);
}
