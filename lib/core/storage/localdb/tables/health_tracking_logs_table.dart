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
    heart_rate_bpm INTEGER,
    oxygen_saturation REAL,
    daily_score INTEGER,
    mood TEXT,

    log_date TEXT,
    created_at TEXT,
    updated_at TEXT,

    UNIQUE(user_id, log_date),
    FOREIGN KEY(user_id) REFERENCES users(id)
    ON DELETE CASCADE
  )
  ''';
}
