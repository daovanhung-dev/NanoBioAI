class PersonalScheduleAiStagingTable {
  static const tableName = 'personal_schedule_ai_staging';

  static const createTable = '''
  CREATE TABLE IF NOT EXISTS personal_schedule_ai_staging (
    request_id TEXT NOT NULL,
    chunk_key TEXT NOT NULL,
    input_fingerprint TEXT NOT NULL,
    catalog_fingerprint TEXT NOT NULL,
    prompt_version TEXT NOT NULL,
    payload_json TEXT NOT NULL DEFAULT '[]',
    invocation_count INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    PRIMARY KEY(request_id, chunk_key),
    FOREIGN KEY(request_id) REFERENCES personal_schedule_ai_requests(request_id)
      ON DELETE CASCADE
  )
  ''';

  static const createUpdatedIndex = '''
  CREATE INDEX IF NOT EXISTS idx_personal_schedule_ai_staging_updated
  ON personal_schedule_ai_staging(updated_at)
  ''';
}
