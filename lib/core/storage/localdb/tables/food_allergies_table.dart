class FoodAllergiesTable {
  static const tableName = 'food_allergies';

  static const createTable = '''
  CREATE TABLE food_allergies (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    allergy_name TEXT,
    note TEXT,
    created_at TEXT,

    FOREIGN KEY(user_id) REFERENCES users(id)
    ON DELETE CASCADE
  )
  ''';
}
