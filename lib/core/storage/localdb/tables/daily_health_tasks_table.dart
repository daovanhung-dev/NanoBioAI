class DailyHealthTasksTable {
  static const tableName = 'daily_health_tasks';

  static const createTable = '''
  CREATE TABLE IF NOT EXISTS daily_health_tasks (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    task_date TEXT NOT NULL,
    task_code TEXT NOT NULL,
    category TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    target_value REAL,
    current_value REAL DEFAULT 0,
    unit TEXT,
    is_completed INTEGER DEFAULT 0,
    sort_order INTEGER DEFAULT 0,
    source TEXT,
    encouragement TEXT,
    created_at TEXT,
    updated_at TEXT,

    UNIQUE(user_id, task_date, task_code),
    FOREIGN KEY(user_id) REFERENCES users(id)
    ON DELETE CASCADE
  )
  ''';
}
