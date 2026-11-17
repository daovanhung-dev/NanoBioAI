abstract final class NabiEspCredentialTable {
  static const tableName = 'nabi_esp_credentials';

  static const createTable =
      '''
    CREATE TABLE IF NOT EXISTS $tableName (
      user_id TEXT PRIMARY KEY NOT NULL,
      ciphertext TEXT NOT NULL,
      initialization_vector TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';
}
