import 'package:sqflite/sqflite.dart';

import '../tables/personal_schedule_ai_staging_table.dart';
import '../seeders/fitness_exercise_sqlite_seeder.dart';

class MigrationV31 {
  const MigrationV31._();

  static Future<void> run(DatabaseExecutor db) async {
    await _addColumn(
      db,
      'exercise_catalog',
      'source_catalog',
      "TEXT NOT NULL DEFAULT 'legacy_m02'",
    );
    await _addColumn(
      db,
      'exercise_catalog',
      'source_provenance',
      "TEXT NOT NULL DEFAULT ''",
    );
    await _addColumn(
      db,
      'exercise_catalog',
      'source_hash',
      "TEXT NOT NULL DEFAULT ''",
    );
    await _addColumn(
      db,
      'exercise_catalog',
      'review_status',
      "TEXT NOT NULL DEFAULT 'active_legacy'",
    );
    await _addColumn(
      db,
      'exercise_catalog',
      'source_payload_json',
      "TEXT NOT NULL DEFAULT '{}'",
    );
    await db.execute(PersonalScheduleAiStagingTable.createTable);
    await db.execute(PersonalScheduleAiStagingTable.createUpdatedIndex);
    await FitnessExerciseSqliteSeeder.seed(db);
  }

  static Future<void> ensureSchema(DatabaseExecutor db) async {
    final columns = await _columns(db, 'exercise_catalog');
    const required = {
      'source_catalog',
      'source_provenance',
      'source_hash',
      'review_status',
      'source_payload_json',
    };
    if (columns.isNotEmpty && !columns.containsAll(required)) {
      await run(db);
      return;
    }
    await db.execute(PersonalScheduleAiStagingTable.createTable);
    await db.execute(PersonalScheduleAiStagingTable.createUpdatedIndex);
  }

  static Future<Set<String>> _columns(DatabaseExecutor db, String table) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return rows.map((row) => row['name']?.toString() ?? '').toSet();
  }

  static Future<void> _addColumn(
    DatabaseExecutor db,
    String table,
    String column,
    String definition,
  ) async {
    if (!(await _columns(db, table)).contains(column)) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }
}
