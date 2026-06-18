class NutritionLogsTable {
  static const tableName = 'nutrition_logs';

  static const createTable = '''
  CREATE TABLE nutrition_logs (
    id TEXT PRIMARY KEY,
    user_id TEXT,

    food_name TEXT,
    calories INTEGER,

    protein REAL,
    carbs REAL,
    fat REAL,

    meal_type TEXT,
    eaten_at TEXT,

    FOREIGN KEY(user_id) REFERENCES users(id)
    ON DELETE CASCADE
  )
  ''';
}
