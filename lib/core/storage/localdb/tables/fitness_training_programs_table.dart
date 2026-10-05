class FitnessTrainingProgramsTable {
  static const tableName = 'fitness_training_programs';

  static const createTable = '''
CREATE TABLE IF NOT EXISTS fitness_training_programs (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  request_id TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('preview', 'active', 'archived')),
  active_week INTEGER NOT NULL CHECK (active_week BETWEEN 1 AND 4),
  quota_committed INTEGER NOT NULL DEFAULT 0,
  parent_program_id TEXT,
  program_json TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE(user_id, request_id),
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
)
''';

  static const createStatusIndex = '''
CREATE INDEX IF NOT EXISTS idx_fitness_programs_user_status
ON fitness_training_programs(user_id, status, updated_at)
''';
}
