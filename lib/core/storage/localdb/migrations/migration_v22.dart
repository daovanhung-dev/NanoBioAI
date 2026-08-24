import 'package:sqflite/sqflite.dart';

/// Local-only schema for the PLUS Food Scan feature.
///
/// These tables are intentionally not registered in UserDataSyncTables or the
/// sync outbox. Scan images and rich AI/health analysis remain on-device while
/// the confirmed nutrition log continues through the existing cloud-sync path.
class MigrationV22 {
  const MigrationV22._();

  static Future<void> run(Database db) => ensureSchema(db);

  static Future<void> ensureSchema(DatabaseExecutor db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS food_scan_analyses (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  image_local_path TEXT NOT NULL,
  input_type TEXT NOT NULL DEFAULT 'unclear',
  analysis_confidence REAL NOT NULL DEFAULT 0,
  total_calories INTEGER NOT NULL DEFAULT 0,
  health_status TEXT NOT NULL DEFAULT 'insufficientData',
  health_score INTEGER,
  result_json TEXT NOT NULL,
  nutrition_log_id TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
)
''');
    await db.execute('''
CREATE INDEX IF NOT EXISTS idx_food_scan_analyses_user_created
ON food_scan_analyses(user_id, created_at DESC)
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS food_scan_items (
  id TEXT PRIMARY KEY,
  scan_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  food_name TEXT NOT NULL,
  estimated_weight_g REAL NOT NULL DEFAULT 0,
  confirmed_weight_g REAL NOT NULL DEFAULT 0,
  portion_description TEXT,
  cooking_method TEXT,
  ingredients_json TEXT NOT NULL DEFAULT '[]',
  possible_allergens_json TEXT NOT NULL DEFAULT '[]',
  nutrition_source TEXT NOT NULL DEFAULT 'ai_fallback',
  nutrition_json TEXT NOT NULL,
  confidence REAL NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY(scan_id) REFERENCES food_scan_analyses(id) ON DELETE CASCADE,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
)
''');
    await db.execute('''
CREATE INDEX IF NOT EXISTS idx_food_scan_items_scan_order
ON food_scan_items(scan_id, sort_order)
''');
  }
}
