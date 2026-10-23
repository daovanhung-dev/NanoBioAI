# Configuration, Deployment & Operations

## Config

- New project default: `pydantic-settings` đọc environment variables; local `.env` chỉ khi developer chọn và được gitignore. `.env.example` toàn placeholder.
- Secrets qua runtime env/secret manager, KHÔNG nằm trong Git tracked constants. Secrets typed with `SecretStr`, không log hoặc dump config.
- Bắt buộc tách `local`, `test`, `staging`, `production`; fail-fast khi thiếu signing key/DB URL ở production.
- `DATABASE_URL`, JWT secret/key, refresh pepper và credentials phải là per environment; rotate procedure documented.

## Runtime

- Uvicorn/Gunicorn workers cấu hình theo benchmark, không cố định số lượng từ template.
- Reverse proxy/ingress terminate HTTPS, enforce trusted proxy headers only for trusted hops; restrict docs in production theo policy.
- Docker multi-stage/minimal non-root image, pinned lockfile, resource limits, graceful shutdown, probes. Không bake `.env` vào image.
- DB pool size theo instance x worker count; tránh thổi quá connection limits của Neon/pooler.
- Redis/object storage/queue optional, chỉ provision khi sản phẩm cần.

## Delivery process

1. PR review + tests/scan pass.
2. Deploy to staging; migration safety check; backup/restore drill for destructive changes.
3. Canary/rolling release khi cần; monitor error rate/p95/DB health.
4. Rollback application path; database backward-compatible migration by expand/contract.
5. Incident playbook: service owner, alerts, logs/tracing, runbook and escalation.

## Security operations

- Never print token/private key/DSN; redact secrets from crash reporting/CI artifacts.
- RBAC on production dashboard/DB, least privilege service account; audit manual interventions.
- No direct prod DB writes, schema drops, destructive deployment or secret rotation without authorized change request.

## Readiness strategy

`/health/live` = app process is alive. `/health/ready` = app can serve requests dependent on essentials, e.g. DB SELECT 1 within bounded timeout. LLM/email providers should generally not block ready unless essential to the whole app; report them separately.
