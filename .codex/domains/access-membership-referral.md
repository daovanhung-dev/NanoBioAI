# Domain - Access / Membership / Referral Sale

## Source

- `lib/app_versions/v2/features/auth/`
- `lib/app_versions/v2/features/membership_entitlement/`
- `lib/app_versions/v2/features/usage_quota/`
- `lib/app_versions/v2/features/personal_schedule_quota/`
- `lib/app_versions/v2/features/health_scoring/`
- `lib/app_versions/v3/`
- `lib/sale_referral/`
- `lib/services/supabase/`
- `docs/supabase/`

## Access Map

- v1: guest/basic, onboarding and one initial personal schedule.
- v2: authenticated free, AI chat 3/day, schedule generation 3/month, health score from schedule completion history.
- v3: M10 advanced tracking and M11 FamilyPlus are partial paid-gated runtime
  flows. V3 home and the remaining planned feature markers are not implemented
  business capabilities.
- Sale/referral: independent axis, not a membership tier.

The user GoRouter composes V1, V2 and V3 routes. Admin keeps a separate router,
selected by `BioAIApp` only after trusted Admin access resolution. Route
presence alone does not prove paid access or feature completeness.

## Rules

- Membership tier, sale status, referral tree, payment success, commission, and quota counters must come from Supabase/trusted backend.
- Do not trust route params, local SQLite, SharedPreferences, hidden UI state, or client metadata for paid/sale access.
- Flutter must not contain service-role keys or hard-coded payment success.
- User-facing copy must not say `tier`, `entitlement`, `gate`, `commission tree`, `database`, or `webhook`.

## Search

```powershell
rg "membership|subscription|tier|entitlement|quota|limit|referral|commission|sale|FamilyPlus|Plus" lib docs .codex
rg "AuthGate|auth|session|onboarding_status|subscription_tier|referral_code" lib/app_versions lib/services test
```
