class HealthConditionsTable {
  static const tableName = 'health_conditions';

  static const createTable = '''
  CREATE TABLE health_conditions (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    condition_code TEXT,
    condition_name TEXT,
    severity_level INTEGER,
    created_at TEXT,

    FOREIGN KEY(user_id) REFERENCES users(id)
    ON DELETE CASCADE
  )
  ''';
}
