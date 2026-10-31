# sleep-safety-dispatch

M31 authenticated no-response escalation function. It re-checks Plus/FamilyPlus access from `effective_user_access`, verifies a recent event whose response is still `noResponse`, applies a server-side rate limit, and loads eligible SafetyContacts by priority. Unverified contacts receive voice only when `allow_unverified_voice_alert` is true. A user-selected “I need help” action stays on-device and is not eligible for this endpoint.

Verified-contact cascade is `priority 1 voice -> priority 1 SMS fallback -> next priority` after an immediate terminal failure. An opted-in unverified contact gets voice only; on failure the cascade skips SMS to that number and continues to the next eligible priority. Submitted/delivered/answered calls are treated as accepted and persisted for provider callback reconciliation.

Required secrets: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SLEEP_SAFETY_PROVIDER_BASE_URL`, `SLEEP_SAFETY_PROVIDER_TOKEN`; optional `SLEEP_SAFETY_PROVIDER_WEBHOOK_SECRET` for callback authentication.
