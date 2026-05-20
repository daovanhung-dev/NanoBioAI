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

    created_at TEXT,

    FOREIGN KEY(user_id) REFERENCES users(id)
    ON DELETE CASCADE
  )
  ''';
}