# Legacy Supabase archive

This directory preserves the former Supabase project, SQL rebuild scripts,
Edge Functions, and related tooling for historical reference. They are not part
of the NanoBio runtime, client build, release workflow, or active deployment.

Do not deploy or run these scripts against Supabase. The active service source
is the FastAPI application in `backend/`, with schema changes in
`backend/alembic/` and clients configured through `API_BASE_URL`.

The old operational guide is retained as `sql/README.md`; its commands describe
the former architecture and are not current deployment instructions.
