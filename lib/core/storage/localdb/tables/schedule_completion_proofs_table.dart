class ScheduleCompletionProofsTable {
  static const tableName = 'schedule_completion_proofs';

  static const createTable = '''
  CREATE TABLE IF NOT EXISTS schedule_completion_proofs (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    schedule_item_id TEXT NOT NULL,
    reward_eligibility_id TEXT,
    completion_attempt_id TEXT,
    schedule_date TEXT NOT NULL,
    start_time TEXT NOT NULL,
    schedule_title TEXT NOT NULL,
    local_path TEXT NOT NULL,
    path_kind TEXT NOT NULL DEFAULT 'relative',
    captured_at TEXT NOT NULL,
    completed_at TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    cloud_object_path TEXT,
    upload_status TEXT NOT NULL DEFAULT 'local_only',
    reward_status TEXT NOT NULL DEFAULT 'not_eligible',
    reversed_at TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
  ''';

  static const createUserDateIndex = '''
  CREATE INDEX IF NOT EXISTS idx_schedule_completion_proofs_user_date
  ON schedule_completion_proofs(user_id, schedule_date DESC, captured_at DESC)
  ''';

  static const createScheduleIndex = '''
  CREATE INDEX IF NOT EXISTS idx_schedule_completion_proofs_schedule
  ON schedule_completion_proofs(schedule_item_id, status, captured_at DESC)
  ''';

  static const createEligibilityIndex = '''
  CREATE INDEX IF NOT EXISTS idx_schedule_completion_proofs_eligibility
  ON schedule_completion_proofs(reward_eligibility_id)
  ''';
}
