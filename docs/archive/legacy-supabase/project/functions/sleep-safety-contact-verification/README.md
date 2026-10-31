# sleep-safety-contact-verification

M31 Edge Function for SafetyContact phone verification. It authenticates the current user, rate-limits OTP issuance, stores only a SHA-256 code hash, and marks verification fields using service-role access after a correct code. The OTP is sent through the provider-neutral `_shared/sleep_safety_provider.ts` adapter and is never returned to Flutter.

Required secrets: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SLEEP_SAFETY_PROVIDER_BASE_URL`, `SLEEP_SAFETY_PROVIDER_TOKEN`.
