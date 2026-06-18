class MealCatalogTable {
  static const tableName = 'meal_catalog';

  static const createTable = '''
  CREATE TABLE IF NOT EXISTS meal_catalog (
    code TEXT PRIMARY KEY,
    meal_type TEXT NOT NULL,
    meal_name TEXT NOT NULL,
    description TEXT NOT NULL,
    cooking_instructions TEXT NOT NULL,
    calories INTEGER NOT NULL,
    protein REAL NOT NULL,
    carbs REAL NOT NULL,
    fat REAL NOT NULL,
    fiber REAL NOT NULL,
    water_ml INTEGER NOT NULL,
    is_active INTEGER DEFAULT 1,
    created_at TEXT,
    updated_at TEXT
  )
  ''';

  static const createTypeIndex = '''
  CREATE INDEX IF NOT EXISTS idx_meal_catalog_type
  ON meal_catalog(meal_type, is_active)
  ''';
}
