# Admin App Surface

Admin is a separate app surface beside `v1`, `v2`, and `v3`.

Guardrails:

- Entry point is `lib/main_admin.dart`.
- UI must call providers/controllers, not Supabase or SQL directly.
- Mutations must go through Admin RPC with permission, reason, idempotency, and
  audit.
- Admin must not import user-version presentation/controllers or
  `sale_referral` modules.
- Flutter must not contain service-role keys or trusted payment secrets.
