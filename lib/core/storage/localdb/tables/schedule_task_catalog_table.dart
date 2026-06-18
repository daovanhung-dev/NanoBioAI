class ScheduleTaskCatalogTable {
  static const tableName = 'schedule_task_catalog';

  static const createTable = '''
  CREATE TABLE IF NOT EXISTS schedule_task_catalog (
    code TEXT PRIMARY KEY,
    category TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    target_value REAL NOT NULL,
    unit TEXT NOT NULL,
    encouragement TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    is_active INTEGER DEFAULT 1,
    created_at TEXT,
    updated_at TEXT
  )
  ''';

  static const createCategoryIndex = '''
  CREATE INDEX IF NOT EXISTS idx_schedule_task_catalog_category
  ON schedule_task_catalog(category, is_active)
  ''';
}
