class MealCatalogTable {
  static const tableName = 'meal_catalog';

  static const createTable = '''
  CREATE TABLE IF NOT EXISTS meal_catalog (
    code TEXT PRIMARY KEY,
    meal_type TEXT NOT NULL,
    meal_name TEXT NOT NULL,
    description TEXT NOT NULL,
    cooking_instructions TEXT NOT NULL,
    calories INTEGER NOT NULL DEFAULT 0,
    protein REAL NOT NULL DEFAULT 0,
    carbs REAL NOT NULL DEFAULT 0,
    fat REAL NOT NULL DEFAULT 0,
    fiber REAL NOT NULL DEFAULT 0,
    water_ml INTEGER NOT NULL DEFAULT 0,
    health_topic_code TEXT,
    health_topic_name TEXT,
    health_topic_description TEXT,
    chapter_number INTEGER,
    chapter_name TEXT,
    ingredients_json TEXT NOT NULL DEFAULT '[]',
    cooking_steps_json TEXT NOT NULL DEFAULT '[]',
    benefits TEXT,
    serving_size TEXT,
    allergen_tags_json TEXT NOT NULL DEFAULT '[]',
    avoid_condition_tags_json TEXT NOT NULL DEFAULT '[]',
    nutrition_status TEXT NOT NULL DEFAULT 'approved',
    constraint_metadata_status TEXT NOT NULL DEFAULT 'approved',
    metadata_status TEXT NOT NULL DEFAULT 'approved',
    is_plan_eligible INTEGER NOT NULL DEFAULT 1,
    source_name TEXT,
    source_page INTEGER,
    source_chapter TEXT,
    source_topic TEXT,
    source_recipe_order INTEGER,
    source_hash TEXT,
    version INTEGER NOT NULL DEFAULT 1,
    is_active INTEGER DEFAULT 1,
    created_at TEXT,
    updated_at TEXT
  )
  ''';

  static const createTypeIndex = '''
  CREATE INDEX IF NOT EXISTS idx_meal_catalog_type
  ON meal_catalog(meal_type, is_active, is_plan_eligible)
  ''';

  static const createTopicIndex = '''
  CREATE INDEX IF NOT EXISTS idx_meal_catalog_topic
  ON meal_catalog(health_topic_code, is_active)
  ''';

  static const createSourceHashIndex = '''
  CREATE INDEX IF NOT EXISTS idx_meal_catalog_source_hash
  ON meal_catalog(source_hash, version)
  ''';
}
