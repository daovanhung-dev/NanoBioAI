class AIInsightsTable {
  static const tableName = 'ai_insights';

  static const createTable = '''
  CREATE TABLE ai_insights (
    id TEXT PRIMARY KEY,
    user_id TEXT,

    insight_type TEXT,
    title TEXT,
    content TEXT,
    risk_level TEXT,

    created_at TEXT,

    FOREIGN KEY(user_id) REFERENCES users(id)
    ON DELETE CASCADE
  )
  ''';
}