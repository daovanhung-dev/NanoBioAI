# Coding Conventions

- Add types to public functions and avoid `Any` unless crossing an untyped boundary.
- Keep request/response schemas in `models.py`; use safe explicit response views rather than ORM serialization.
- Keep `query.py` limited to persistence reads/writes with bound values; never commit there.
- Keep pure deterministic rules in `validate.py`; no database or network access from validators.
- Use one transaction per state-changing use case; rollback on failure and map integrity races to stable business errors.
- Parse identity from the access token. Self-service operations derive owner ID from the authenticated principal.
- Never log passwords, refresh/access tokens, phone numbers, health data, payment tokens, verification codes, provider payloads, or secret values.
- Do not store secrets in docs, tests, fixtures, migrations, or repository `.env` files.
