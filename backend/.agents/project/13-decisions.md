# Accepted Decisions

| ID | Decision | State |
|---|---|---|
| NBI-BE-001 | FastAPI modular monolith on the existing `src/nanobio_backend` scaffold | Accepted |
| NBI-BE-002 | Ubuntu native PostgreSQL + systemd backend | Accepted; deployment deferred |
| NBI-BE-003 | First-party phone/password Auth, Argon2id, JWT access and rotating opaque refresh | Accepted |
| NBI-BE-004 | No import of Supabase users/data in this phase | Accepted |
| NBI-BE-005 | Historical baseline: Flutter AI stayed on-device while the separate FastAPI text endpoint used loopback Ollama behind a default-off feature flag. Superseded by the user-approved 2026-10-30 NanoBio Flutter backend-AI migration; current app source routes AI through authenticated backend endpoints with no local text/vision fallback. | Superseded |
| NBI-BE-006 | Empty function directories remain `NOT_FOUND` | Accepted |
| NBI-BE-007 | App, Admin Web and website source remain unchanged | Accepted |
| NBI-BE-008 | NanoBio worklogs remain in `docs/worklog/` | Accepted |
