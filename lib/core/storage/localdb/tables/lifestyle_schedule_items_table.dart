class LifestyleScheduleItemsTable {
  static const tableName = 'lifestyle_schedule_items';

  static const createTable = '''
  CREATE TABLE IF NOT EXISTS lifestyle_schedule_items (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    schedule_date TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    source_type TEXT NOT NULL,
    source_id TEXT,
    target_value REAL DEFAULT 1,
    current_value REAL DEFAULT 0,
    unit TEXT,
    is_completed INTEGER DEFAULT 0,
    sort_order INTEGER DEFAULT 0,
    ai_generated INTEGER DEFAULT 1,
    encouragement TEXT,
    created_at TEXT,
    updated_at TEXT,

    FOREIGN KEY(user_id) REFERENCES users(id)
    ON DELETE CASCADE
  )
  ''';

  static const createDateIndex = '''
  CREATE INDEX IF NOT EXISTS idx_lifestyle_schedule_user_date
  ON lifestyle_schedule_items(user_id, schedule_date, sort_order)
  ''';

  static const createSourceIndex = '''
  CREATE INDEX IF NOT EXISTS idx_lifestyle_schedule_source
  ON lifestyle_schedule_items(source_type, source_id)
  ''';
}
