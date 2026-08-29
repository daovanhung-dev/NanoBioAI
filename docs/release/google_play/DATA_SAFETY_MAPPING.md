# Google Play Data Safety mapping

This is a source-backed preparation map, not a submitted Play Console form.
The product/legal owner must confirm the final answers against the release
build and deployed Supabase project.

The companion Privacy Policy is [publish-ready source](PRIVACY_POLICY_PUBLIC_PAGE.md)
but remains `BLOCKED_EXTERNAL` until the legal owner supplies the real identity,
contacts, provider/retention terms, and a public HTTPS page.

| Category / flow | Collected? | Shared with | Purpose | Required? | Lifetime | Encryption / deletion | Evidence / status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Account and profile | Yes when a user signs in | Supabase | Account, profile and sync | Account-required | Persisted | TLS/Supabase controls; deleted with account | Auth/profile repository; policy review open |
| Health/body metrics, meals, exercise and schedules | Yes when entered | Supabase | Personal wellness features | Feature-optional | Persisted | TLS/Supabase RLS; user deletion/cascade | Canonical SQL/RLS; sandbox deletion open |
| AI prompts and responses | Yes when AI is used | Supabase Edge Function and configured AI provider | Generate wellness guidance and summaries | Feature-optional | Request/response persistence follows feature; provider retention must be confirmed | TLS; account deletion and provider policy review open | `nabi-ai-generate`; legal/DPA review open |
| AI content report | Yes when user reports an assistant message | Supabase service-role moderation path | Safety review and abuse prevention | Optional | Persisted until approved retention policy | TLS; account linkage anonymized on deletion | `report-ai-content`, `ai_content_reports`; retention approval open |
| Camera/gallery image | Yes only when user selects or captures an image | Backend feature endpoint if scan is submitted | Food scan or user-requested proof | Feature-optional | Ephemeral unless feature explicitly stores result | TLS; local cache cleared with account where applicable | System picker/camera source; verify final endpoint policy |
| Microphone/audio | Microphone may be active only for Sleep Safety; audio handling must be confirmed | No audio provider is intended by the Flutter contract | User-enabled safety monitoring | Feature-optional | Runtime monitoring; raw audio is not intended to persist; confirm derived-signal storage | Permission + foreground service; device test/policy review open | `SleepSafetyForegroundService`; manual gate open |
| Device/installation identifiers | Potentially generated for rate limits/reporting | Supabase | Abuse prevention and report correlation | Feature-optional | Persisted only where report contract requires | Anonymized on account deletion; exact retention needs approval | report datasource/schema; policy review open |
| Diagnostics/logs | Limited operational logs | App backend/observability if configured | Reliability and troubleshooting | Optional | Retention policy required | Avoid secrets/health payloads; policy review open | `AITraceLogger` and app logging; inventory open |
| Google Play purchase token | Yes during trusted verification | Google Play and Supabase Edge Function | Verify purchase and entitlement | Membership-required | Ledger keeps token hash and reconciliation fields | TLS; account link set `NULL` on deletion; legal retention duration required | `google-play-verify-purchase`, ledger SQL |
| Family/emergency contact data | Yes when family feature is used | Supabase | FamilyPlus scope and emergency support | Feature-optional | Persisted | RLS; delete/cascade or `SET NULL` per FK policy | Family SQL/RPCs; sandbox matrix open |
| Referral/Sale data | Yes when referral/Sale feature is used | Supabase/admin roles | Referral attribution, payouts and fraud review | Feature-optional | Persisted for operational review | RLS; reviewer/owner links follow FK policy | Sale/referral SQL; legal retention open |

No client-held Gemini credential is collected or shipped. Public privacy and
account-deletion URLs are release-configured through `AppEnv` and are hidden
when absent, so the final build must wire live HTTPS pages before submission.
The final form must still name the actual third parties and
processing/retention terms configured for the deployed Edge Function.
