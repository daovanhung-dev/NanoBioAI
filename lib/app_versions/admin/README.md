# Admin App Surface

Lifecycle: `Current`. Implementation: `Partial` by static source at baseline
`25018e8`; Supabase RPC/RLS/device behavior is not implied to be PASS.

Admin remains an isolated presentation surface, but it is selected by the unified app bootstrap beside `v1`, `v2`, and `v3`.

Guardrails:

- Entry point is `lib/main.dart`; the app selects Admin after trusted role resolution.
- UI must call providers/controllers, not Supabase or SQL directly.
- Mutations must go through Admin RPC with permission, reason, idempotency, and
  audit.
- Admin must not import user-version presentation/controllers or
  `sale_referral` modules.
- Flutter must not contain service-role keys or trusted payment secrets.
