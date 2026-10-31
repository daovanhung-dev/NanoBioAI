# Admin App Surface

Admin is an isolated presentation surface selected by the unified app bootstrap
beside `v1`, `v2`, and `v3`.

Guardrails:

- Entry point is `lib/main.dart`; the app selects Admin after trusted backend
  role resolution.
- UI calls providers/controllers; all remote reads and writes use the
  versioned NanoBio API.
- Mutations require server-side permission checks, a reason, idempotency, and
  audit records.
- Admin must not import user-version presentation/controllers or
  `sale_referral` modules.
- Flutter must not contain service-role keys or trusted payment secrets.
