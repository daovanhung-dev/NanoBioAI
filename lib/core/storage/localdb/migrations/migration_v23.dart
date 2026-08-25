import 'package:sqflite/sqflite.dart';

import '../tables/sleep_safety_tables.dart';

/// Adds local-only nightly sleep-safety analytics.
///
/// The table stores numeric metadata and structured AI summaries only. Raw
/// audio, PCM, recordings and transcripts are intentionally absent.
class MigrationV23 {
  const MigrationV23._();

  static Future<void> run(Database db) => ensureSchema(db);

  static Future<void> ensureSchema(DatabaseExecutor db) {
    return SleepSafetyTables.createAnalysis(db);
  }
}
