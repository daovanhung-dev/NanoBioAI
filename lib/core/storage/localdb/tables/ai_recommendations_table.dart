class AIRecommendationsTable {
  static const tableName = 'ai_recommendations';

  static const createTable = '''
  CREATE TABLE ai_recommendations (
    id TEXT PRIMARY KEY,
    user_id TEXT,

    recommendation_type TEXT,
    title TEXT,
    description TEXT,
    action_text TEXT,

    is_read INTEGER DEFAULT 0,

    created_at TEXT,

    FOREIGN KEY(user_id) REFERENCES users(id)
    ON DELETE CASCADE
  )
  ''';
}