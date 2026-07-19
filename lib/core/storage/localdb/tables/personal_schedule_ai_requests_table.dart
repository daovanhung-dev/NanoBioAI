class PersonalScheduleAiRequestsTable {
  static const tableName = 'personal_schedule_ai_requests';

  static const createTable = '''
  CREATE TABLE IF NOT EXISTS personal_schedule_ai_requests (
    request_id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    actor_mode TEXT NOT NULL,
    status TEXT NOT NULL,
    start_date TEXT,
    days INTEGER NOT NULL DEFAULT 7,
    meal_count INTEGER NOT NULL DEFAULT 0,
    exercise_count INTEGER NOT NULL DEFAULT 0,
    schedule_item_count INTEGER NOT NULL DEFAULT 0,
    generation_source TEXT NOT NULL DEFAULT 'unknown',
    error_code TEXT,
    created_at TEXT,
    updated_at TEXT,
    completed_at TEXT,

    CHECK(actor_mode IN ('initial_guest', 'member_new')),
    CHECK(status IN ('generating', 'succeeded', 'failed')),
    FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
  )
  ''';

  static const createUserModeIndex = '''
  CREATE INDEX IF NOT EXISTS idx_personal_schedule_ai_requests_user_mode
  ON personal_schedule_ai_requests(user_id, actor_mode, status, updated_at)
  ''';
}
