# DD-AUTH-PLAN-001 - Thứ tự triển khai và dependency gate

## 1. Phases

### Phase A - Database foundation

1. Deploy multi-tenant schema.
2. Deploy bootstrap trigger patch.
3. Deploy lifecycle migration `database/001_add_auth_lifecycle_fields.sql`.
4. Confirm RLS/grants and run `database/002_verify_auth_profile_integrity.sql`.
5. Backfill old users if any.

**Gate:** Không có user nào thiếu `public.users`, `health_profiles`, `lifestyle_habits`.

### Phase B - Auth data/domain layer

1. Create entities, commands, repository contract.
2. Implement Supabase Auth datasource methods.
3. Implement profile read used by AuthGate.
4. Add typed error mapping.

**Gate:** Unit tests/mock tests cover route-state mapping without UI.

### Phase C - Presentation and routing

1. Register/Login/Verify/Forgot/Reset pages.
2. AuthController state handling.
3. AuthGate and router redirect policy.
4. Deep-link integration for verification/recovery.

**Gate:** All core paths reach expected route from test matrix.

### Phase D - Onboarding integration

1. Update existing base profile rows.
2. Persist draft/`in_progress` state.
3. Finalize completed status only after validation.
4. Ensure dashboard not manually bypassed.

**Gate:** resume and completed flows pass.

### Phase E - Settings and account safety

1. Profile editing.
2. Change password/recovery.
3. Logout cache cleanup.
4. Backend/Edge Function account deletion.

**Gate:** service role has no client exposure; delete cascade verified in non-production environment.

## 2. Out-of-scope protection

Do not add Google login, medical roles, subscription payment, 2FA or cross-user sharing in this module without a separate BD and DD. Those introduce new provider, permission and data-retention requirements.

## 3. Commit segmentation

- `chore(db): add auth lifecycle profile fields`
- `feat(auth): implement auth repository and route state`
- `feat(auth): add email-password registration and verification`
- `feat(auth): add login session auth gate`
- `feat(onboarding): persist auth onboarding lifecycle`
- `feat(settings): add profile security actions`
- `test(auth): add rls and auth lifecycle coverage`

Each commit remains single-purpose and references DD/test IDs in its body where project convention supports it.
