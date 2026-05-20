class UsersTable {
  static const tableName = 'users';

  static const createTable = '''
  CREATE TABLE users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE,
    phone TEXT UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    gender TEXT,
    birth_year INTEGER,
    created_at TEXT,
    updated_at TEXT
  )
  ''';
}