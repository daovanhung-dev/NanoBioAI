class HealthScoreLedgersTable {
  static const tableName = 'health_score_ledgers';

  static const createTable = '''
  CREATE TABLE IF NOT EXISTS health_score_ledgers (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    subject_id TEXT,
    period_start TEXT NOT NULL,
    period_end TEXT NOT NULL,
    score INTEGER NOT NULL DEFAULT 0,
    formula_version TEXT NOT NULL,
    breakdown TEXT NOT NULL DEFAULT '{}',
    idempotency_key TEXT,
    calculated_at TEXT NOT NULL,
    created_at TEXT,
    updated_at TEXT,

    FOREIGN KEY(user_id) REFERENCES users(id)
    ON DELETE CASCADE,
    UNIQUE(user_id, period_start, period_end, formula_version)
  )
  ''';

  static const createSubjectPeriodIndex = '''
  CREATE INDEX IF NOT EXISTS idx_health_score_ledgers_subject_period
  ON health_score_ledgers(subject_id, period_end DESC, formula_version)
  ''';

  static const createUserPeriodIndex = '''
  CREATE INDEX IF NOT EXISTS idx_health_score_ledgers_user_period
  ON health_score_ledgers(user_id, period_end DESC, formula_version)
  ''';
}
