# Workflow - Legacy Supabase Archive

This workflow is read-only. The former SQL, migrations, and Edge Functions are
archived at `docs/archive/legacy-supabase/`; they are not a live service or a
deployment target.

For current schema or API changes, use the backend workflow and edit
`backend/alembic/` plus `backend/src/nanobio_backend/`. Do not run the archived
SQL, Supabase CLI, Edge Functions, or database migration tools against a live
project. Read archived contracts only when mapping or validating behavior that
still needs a backend equivalent.
