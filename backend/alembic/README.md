# Alembic

The first migration creates the backend-owned schema from `db.models`. It does not copy Supabase platform schemas or seed user data. After this initial revision, schema changes must use explicit versioned Alembic revisions and be tested against an empty disposable PostgreSQL database.
