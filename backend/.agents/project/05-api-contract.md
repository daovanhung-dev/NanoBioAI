# API Contract

- Base path: `/api/v1`; readiness/liveness are `/health/ready` and `/health/live`.
- Success envelope: `success`, `businessCode`, `message`, `data`, `meta`, `traceId`.
- Error envelope has the same fields and always `data: null`.
- Accept a valid UUID `X-Trace-Id`, otherwise generate one; return it in the header and envelope.
- Use bearer access tokens on protected routes and document them in OpenAPI.
- Use resource/action paths, typed request schemas, explicit pagination bounds, and allowlisted sorts.
- FamilyPlus routes use `/family-plus/context`, `/family-plus/group`, and
  `/family-plus/members`; enforce an active plan and owner-scoped subjects.
- Never return ORM objects, credentials, password hashes, provider secrets, or private file paths.
- AI legacy routes are present but return 503 `FEATURE_NOT_ENABLED`; six source-less functions have no route.
- HTTP status must match error/success semantics. Unexpected errors are safe and include only a trace ID.
