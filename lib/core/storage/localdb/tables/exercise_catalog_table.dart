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
    equipment_json TEXT NOT NULL DEFAULT '[]',
    movement_areas_json TEXT NOT NULL DEFAULT '[]',
    limitation_tags_json TEXT NOT NULL DEFAULT '[]',
    condition_contraindications_json TEXT NOT NULL DEFAULT '[]',
    safety_status TEXT NOT NULL DEFAULT 'unreviewed',
    safety_source TEXT,
    safety_verified_at TEXT,
    source_catalog TEXT NOT NULL DEFAULT 'legacy_m02',
    source_provenance TEXT NOT NULL DEFAULT '',
    source_hash TEXT NOT NULL DEFAULT '',
    review_status TEXT NOT NULL DEFAULT 'active_legacy',
    source_payload_json TEXT NOT NULL DEFAULT '{}',
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
