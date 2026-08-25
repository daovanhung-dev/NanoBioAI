import 'package:sqflite/sqflite.dart';

import '../tables/sleep_safety_tables.dart';
import 'migration_v23.dart';

class MigrationV21 {
  const MigrationV21._();

  static Future<void> run(Database db) => ensureSchema(db);

  /// `DatabaseService.onOpen` already calls this idempotent hook for every
  /// database at v21+, so it is also the safest repair point for schemas that
  /// were added after v21 but shipped without explicit lifecycle wiring.
  static Future<void> ensureSchema(DatabaseExecutor db) async {
    await SleepSafetyTables.create(db);
    await MigrationV23.ensureSchema(db);
  }
}
