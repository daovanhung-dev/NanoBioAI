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
    subscription_tier TEXT DEFAULT 'free',
    product_access_status TEXT DEFAULT 'guest',
    sale_status TEXT DEFAULT 'none',
    onboarding_status TEXT DEFAULT 'not_started',
    onboarding_completed_at TEXT,
    created_at TEXT,
    updated_at TEXT
  )
  ''';
}
