class ExerciseCatalogTable {
  static const tableName = 'exercise_catalog';

  static const createTable = '''
  CREATE TABLE IF NOT EXISTS exercise_catalog (
    code TEXT PRIMARY KEY,
    category TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    unit TEXT NOT NULL,
    encouragement TEXT NOT NULL,
    min_target REAL NOT NULL,
    max_target REAL NOT NULL,
    default_target REAL NOT NULL,
    intensity_level TEXT NOT NULL,
    is_active INTEGER DEFAULT 1,
    created_at TEXT,
    updated_at TEXT
  )
  ''';

  static const createCategoryIndex = '''
  CREATE INDEX IF NOT EXISTS idx_exercise_catalog_category
  ON exercise_catalog(category, is_active)
  ''';
}
