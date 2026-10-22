# Errors and Observability

Every request has a trace ID. Expected API errors use stable business codes and safe Vietnamese/English messages; unexpected exceptions are logged with trace ID and stack internally but return no detail. Liveness checks process response; readiness executes `SELECT 1` against PostgreSQL. Do not include PII, health records, auth tokens, secrets, or provider payloads in logs.
