class MealPlansTable {
  static const tableName = 'meal_plans';

  static const createTable = '''
  CREATE TABLE meal_plans (

    id TEXT PRIMARY KEY,

    user_id TEXT,

    plan_date TEXT,

    meal_type TEXT,

    meal_name TEXT,

    description TEXT,

    calories INTEGER,

    protein REAL,

    carbs REAL,

    fat REAL,

    fiber REAL,

    water_ml INTEGER,

    meal_order INTEGER,

    is_completed INTEGER DEFAULT 0,

    ai_generated INTEGER DEFAULT 1,

    created_at TEXT,

    updated_at TEXT,

    FOREIGN KEY(user_id)
    REFERENCES users(id)
    ON DELETE CASCADE

  )
  ''';
}
