class WellnessRankSummaryCacheTable {
  static const tableName = 'wellness_rank_summary_cache';

  static const createTable =
      '''
  CREATE TABLE IF NOT EXISTS $tableName (
    user_id TEXT PRIMARY KEY,
    rank_code TEXT NOT NULL,
    rank_level INTEGER NOT NULL,
    title TEXT NOT NULL,
    experience_points INTEGER NOT NULL DEFAULT 0,
    current_rank_threshold INTEGER NOT NULL DEFAULT 0,
    next_rank_threshold INTEGER,
    experience_to_next_rank INTEGER NOT NULL DEFAULT 0,
    rank_progress_exp INTEGER NOT NULL DEFAULT 0,
    rank_progress_target INTEGER NOT NULL DEFAULT 0,
    computed_at TEXT NOT NULL,
    next_decay_at TEXT,
    synced_at TEXT NOT NULL
  )
  ''';
}
