abstract final class MedicationRemindersTable {
  static const tableName = 'medication_reminders';

  static const createTable =
      '''
CREATE TABLE IF NOT EXISTS $tableName (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  medicine_name TEXT NOT NULL,
  times_json TEXT NOT NULL,
  enabled INTEGER NOT NULL DEFAULT 1 CHECK (enabled IN (0, 1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
)
''';

  static const createUserIndex =
      'CREATE INDEX IF NOT EXISTS idx_medication_reminders_user '
      'ON $tableName(user_id)';
}
