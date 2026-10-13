class FoodEvidenceCacheTable {
  static const tableName = 'food_ingredient_evidence';

  static const createTable = '''
  CREATE TABLE IF NOT EXISTS food_ingredient_evidence (
    normalized_name TEXT PRIMARY KEY,
    queried_name TEXT NOT NULL,
    source_food_id TEXT,
    description TEXT,
    data_type TEXT,
    nutrients_json TEXT,
    source_name TEXT NOT NULL,
    source_url TEXT NOT NULL,
    dataset_version TEXT,
    retrieved_at TEXT NOT NULL,
    evidence_status TEXT NOT NULL
  )
  ''';

  static const createRetrievedIndex = '''
  CREATE INDEX IF NOT EXISTS idx_food_evidence_retrieved
  ON food_ingredient_evidence(retrieved_at)
  ''';
}
