class WellnessPointLedgersTable {
  static const tableName = 'wellness_point_ledgers';

  static const createTable = '''
  CREATE TABLE IF NOT EXISTS wellness_point_ledgers (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    subject_id TEXT,
    source_type TEXT NOT NULL,
    source_id TEXT NOT NULL,
    schedule_date TEXT NOT NULL,
    points_delta INTEGER NOT NULL,
    program_code TEXT NOT NULL,
    idempotency_key TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,

    FOREIGN KEY(user_id) REFERENCES users(id)
    ON DELETE CASCADE,
    UNIQUE(idempotency_key)
  )
  ''';

  static const createUserDateIndex = '''
  CREATE INDEX IF NOT EXISTS idx_wellness_point_ledgers_user_date
  ON wellness_point_ledgers(user_id, schedule_date)
  ''';

  static const createSourceIndex = '''
  CREATE INDEX IF NOT EXISTS idx_wellness_point_ledgers_source
  ON wellness_point_ledgers(source_type, source_id)
  ''';
}
