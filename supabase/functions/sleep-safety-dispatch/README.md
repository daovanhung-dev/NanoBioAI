# sleep-safety-dispatch

M31 authenticated escalation function. It re-checks Plus/FamilyPlus access from `effective_user_access`, verifies a recent escalation-eligible event, applies a server-side rate limit, loads verified SafetyContacts by priority, and submits contact attempts through the provider-neutral HTTP adapter.

The initial cascade is `priority 1 voice -> priority 1 SMS fallback -> priority 2 -> priority 3` when the provider returns an immediate terminal failure. Submitted/delivered/answered calls are treated as accepted and persisted for provider callback reconciliation.

Required secrets: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SLEEP_SAFETY_PROVIDER_BASE_URL`, `SLEEP_SAFETY_PROVIDER_TOKEN`; optional `SLEEP_SAFETY_PROVIDER_WEBHOOK_SECRET` for callback authentication.
