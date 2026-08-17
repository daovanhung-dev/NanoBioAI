class ScheduleHealthCheckInOutboxTable {
  static const tableName = 'schedule_health_checkin_outbox';

  static const createTable = '''
  CREATE TABLE IF NOT EXISTS schedule_health_checkin_outbox (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    schedule_item_id TEXT NOT NULL,
    action_type TEXT NOT NULL,
    payload TEXT NOT NULL DEFAULT '{}',
    completion_token TEXT NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'pending',
    reward_status TEXT,
    points_delta INTEGER NOT NULL DEFAULT 0,
    last_error_code TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    UNIQUE(schedule_item_id, completion_token)
  )
  ''';

  static const createPendingIndex = '''
  CREATE INDEX IF NOT EXISTS idx_schedule_health_checkin_outbox_pending
  ON schedule_health_checkin_outbox(user_id, sync_status, updated_at)
  ''';

  static const createScheduleIndex = '''
  CREATE INDEX IF NOT EXISTS idx_schedule_health_checkin_outbox_schedule
  ON schedule_health_checkin_outbox(schedule_item_id, created_at DESC)
  ''';
}
