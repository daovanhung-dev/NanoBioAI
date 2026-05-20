class HealthProfilesTable {
  static const tableName = 'health_profiles';

  static const createTable = '''
  CREATE TABLE health_profiles (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    occupation TEXT,
    height_cm REAL,
    weight_kg REAL,
    bmi REAL,
    blood_pressure TEXT,
    blood_sugar TEXT,
    created_at TEXT,
    updated_at TEXT,

    FOREIGN KEY(user_id) REFERENCES users(id)
    ON DELETE CASCADE
  )
  ''';
}