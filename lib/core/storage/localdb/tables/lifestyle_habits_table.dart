class LifestyleHabitsTable {
  static const tableName = 'lifestyle_habits';

  static const createTable = '''
  CREATE TABLE lifestyle_habits (
    id TEXT PRIMARY KEY,
    user_id TEXT,

    skip_breakfast INTEGER DEFAULT 0,
    eat_late INTEGER DEFAULT 0,
    eat_sweet INTEGER DEFAULT 0,
    eat_oily INTEGER DEFAULT 0,
    low_vegetable INTEGER DEFAULT 0,
    low_water INTEGER DEFAULT 0,
    fast_food INTEGER DEFAULT 0,
    alcohol INTEGER DEFAULT 0,
    coffee_high INTEGER DEFAULT 0,

    sleep_quality TEXT,
    activity_level TEXT,
    water_per_day TEXT,

    created_at TEXT,

    FOREIGN KEY(user_id) REFERENCES users(id)
    ON DELETE CASCADE
  )
  ''';
}