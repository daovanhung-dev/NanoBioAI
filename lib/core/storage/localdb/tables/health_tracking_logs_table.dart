class HealthTrackingLogsTable {
  static const tableName = 'health_tracking_logs';

  static const createTable = '''
  CREATE TABLE health_tracking_logs (
    id TEXT PRIMARY KEY,
    user_id TEXT,

    weight_kg REAL,
    calories INTEGER,
    water_ml INTEGER,
    sleep_hours REAL,
    stress_level INTEGER,
    steps_count INTEGER,
    mood TEXT,

    created_at TEXT,

    FOREIGN KEY(user_id) REFERENCES users(id)
    ON DELETE CASCADE
  )
  ''';
}