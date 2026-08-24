import 'package:sqflite/sqflite.dart';
import '../tables/sleep_safety_tables.dart';
class MigrationV21 {
  const MigrationV21._();
  static Future<void> run(Database db) => ensureSchema(db);
  static Future<void> ensureSchema(DatabaseExecutor db) => SleepSafetyTables.create(db);
}
