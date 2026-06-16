class NotificationsTable {
  static const tableName = 'notifications';

  static const createTable = '''
  CREATE TABLE notifications (
    id TEXT PRIMARY KEY,
    user_id TEXT,

    title TEXT,
    body TEXT,
    type TEXT,

    is_read INTEGER DEFAULT 0,

    source_type TEXT,
    source_id TEXT,
    scheduled_at TEXT,
    notification_id INTEGER,
    action_status TEXT DEFAULT 'pending',
    responded_at TEXT,
    payload TEXT,
    updated_at TEXT,

    created_at TEXT,

    FOREIGN KEY(user_id) REFERENCES users(id)
    ON DELETE CASCADE
  )
  ''';
}
