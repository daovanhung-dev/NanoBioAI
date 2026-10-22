# Authentication and Security

- Normalize Vietnamese phones to E.164 using the source rule; do not retain email aliases as login credentials.
- Hash passwords with Argon2id. Enforce the source signup range 8..128 characters.
- Issue short-lived signed access tokens and opaque high-entropy refresh tokens; persist only refresh-token hashes, rotate atomically, and reject replay.
- Resolve actor roles from trusted database state. Admin routes use per-operation allowlists; membership and owner checks are server-side.
- Apply rate limits to public signup and sensitive auth/provider operations. Use idempotency on source-backed retriable admin/payment actions.
- Account deletion cleans owned files and database records under one controlled flow; no client-provided subject IDs.
- File paths are generated server-side beneath configured storage root, with size/type limits and ownership checks.
- Secrets live in Ubuntu environment files readable only by the service account or a secret store. Never copy Supabase service-role credentials.
