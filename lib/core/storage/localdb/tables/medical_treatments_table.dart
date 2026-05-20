class MedicalTreatmentsTable {
  static const tableName = 'medical_treatments';

  static const createTable = '''
  CREATE TABLE medical_treatments (
    id TEXT PRIMARY KEY,
    user_id TEXT,
    treatment_name TEXT,
    medication_name TEXT,
    note TEXT,
    created_at TEXT,

    FOREIGN KEY(user_id) REFERENCES users(id)
    ON DELETE CASCADE
  )
  ''';
}