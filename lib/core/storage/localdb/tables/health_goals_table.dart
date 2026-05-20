class HealthGoalsTable {
  static const tableName = 'health_goals';

  static const createTable = '''
  CREATE TABLE health_goals (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    goal_code TEXT,
    goal_name TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT,

    FOREIGN KEY(user_id) REFERENCES users(id)
    ON DELETE CASCADE
  )
  ''';
}