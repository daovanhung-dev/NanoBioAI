# Database

Use SQLAlchemy 2 sync sessions, one per request. Configure `pool_pre_ping`; connect using the environment-provided local PostgreSQL URL. Alembic is the schema source for this backend. Do not copy Supabase's `auth`, `storage`, RLS, cron or platform tables.

Views own `commit()`/rollback. Queries bind all values and never commit. Use constraints for unique identity, ownership and idempotency; use row locks/atomic updates for refresh rotation and membership transitions. Keep provider calls outside transactions.

Migrations contain schema only, never real user/secret data. Apply/test them on an empty disposable database before claiming PostgreSQL migration PASS. Do not connect to or write to production Supabase.

New local accounts receive one owner-linked `self` health subject in the same transaction. FamilyPlus rows reference local subjects and enforce partial uniqueness and owner/member limits in PostgreSQL; do not import existing Supabase subjects here.
