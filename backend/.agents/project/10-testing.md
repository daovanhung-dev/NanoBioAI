# Testing

Use pytest and HTTPX for request contracts; unit tests for phone/password/token helpers and domain rules; integration tests for ownership, RBAC, rate-limit atomicity, idempotency, rollback and concurrent refresh rotation. Provider tests use deterministic fakes and must prove timeout/failure mapping. PostgreSQL-specific transaction/concurrency and empty migration checks require disposable PostgreSQL; SQLite is not equivalent evidence.
