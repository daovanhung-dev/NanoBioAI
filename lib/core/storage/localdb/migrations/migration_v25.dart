import 'package:sqflite/sqflite.dart';

import '../sync/sync_outbox_schema.dart';
import '../tables/fitness_training_programs_table.dart';

class MigrationV25 {
  const MigrationV25._();

  static Future<void> run(Database db) async {
    await ensureSchema(db);
    await SyncOutboxSchema.recreateTriggers(db);
  }

  static Future<void> ensureSchema(DatabaseExecutor db) async {
    await db.execute(FitnessTrainingProgramsTable.createTable);
    await db.execute(FitnessTrainingProgramsTable.createStatusIndex);
  }
}
