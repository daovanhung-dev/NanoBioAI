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

  start_time TEXT,

  end_time TEXT,

  cooking_instructions TEXT,

  is_completed INTEGER,

  ai_generated INTEGER,

  created_at TEXT,

  updated_at TEXT

)
  ''';
}
