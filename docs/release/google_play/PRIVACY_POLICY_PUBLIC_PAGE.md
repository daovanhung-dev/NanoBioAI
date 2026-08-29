# NanoBio Privacy Policy — publish-ready page

**Status: `SOURCE_READY / BLOCKED_EXTERNAL`**

This copy is prepared from the release code and Supabase contracts. It is not
the live Privacy Policy until the product/legal owner replaces the placeholders,
approves the wording, publishes it on a public HTTPS URL, and wires that URL
into the release configuration.

## Who operates NanoBio

- App: **NanoBio** (`com.nanobioai.app`)
- Developer/legal entity: **[LEGAL ENTITY / DEVELOPER NAME]**
- Support and privacy contact: **[REAL SUPPORT EMAIL OR FORM URL]**
- Effective date: **[YYYY-MM-DD]**
- Last updated: **[YYYY-MM-DD]**

## What NanoBio does

NanoBio provides personal wellness planning, health self-tracking, meal and
activity suggestions, reminders, AI-generated guidance, and an optional Sleep
Safety monitoring feature. NanoBio is not a medical device, diagnostic service,
treatment provider, emergency service, or substitute for qualified care.

## Data we process and why

We process only the data needed for a feature that you choose to use:

| Data | Purpose | Where it goes |
| --- | --- | --- |
| Account credentials, profile and onboarding choices | Sign-in, account access, personalization and sync | NanoBio Supabase project |
| Health/body metrics, meals, exercise, schedules and sleep entries | Personal wellness plans, summaries and reminders | Local app database; Supabase when cloud sync is enabled |
| AI prompts, replies and bounded plan context | Generate wellness guidance and summaries | NanoBio Edge Function and the configured AI provider |
| AI safety report (reason, bounded message snapshot, optional note) | Moderation, safety review and abuse prevention | NanoBio report endpoint and moderation table |
| Camera or gallery image selected by you | Food scan or another feature you explicitly submit | The endpoint for that feature; retention must match the feature result shown to you |
| Microphone-derived Sleep Safety signal | User-enabled sleep sound monitoring | Processed by the Android foreground service; raw audio is not intended to be stored or uploaded |
| Installation/device identifier and diagnostics | Rate limiting, report correlation and reliability | NanoBio backend/observability where configured |
| Google Play purchase token and subscription state | Verify membership and reconcile purchases | Google Play and NanoBio verification endpoint; the database keeps a token hash rather than the raw token |
| Family, emergency, referral and Sale data | Features you explicitly use and operational reconciliation | NanoBio Supabase project and authorized staff paths |

The Gemini/API credential used for AI generation is held only as a server-side
Edge Function secret. It is not placed in the Android app, client logs, or a
Dart/Gradle runtime channel.

## Sleep Safety and microphone disclosure

Sleep Safety is optional. Before Android microphone permission is requested,
NanoBio explains that the feature monitors nearby sleep-related sound signals,
keeps a visible foreground notification while active, and is not an emergency
or diagnostic service. Monitoring starts only after you enable it and grant
microphone permission. You can stop it from the in-app control or notification;
denying permission leaves the rest of the app usable.

## Sharing and service providers

NanoBio shares data only with the providers needed for the feature you invoke:
Supabase for authentication/storage/database, the configured AI provider for
AI generation, Google Play for purchase verification, and infrastructure or
observability providers approved by the operator. We do not sell personal
data. The legal owner must insert the actual provider names, data-processing
terms, and contact details before publication.

## Storage, security and retention

Data may be stored locally on your device and in the NanoBio Supabase project.
Transport is protected by the platform/network controls used by these
services, and row-level access controls restrict cloud records to their owner
or an explicitly authorized operational role. The release does not publish a
retention period that has not been approved. The legal owner must specify the
retention period for account records, purchase reconciliation, moderation and
audit records, and any provider retention before this page goes live.

## Account and data deletion

You can request deletion in NanoBio under **Settings → Account → Yêu cầu xóa
tài khoản**. The request authenticates the current account, removes its owned
cloud records and owned schedule-proof objects, applies the documented
anonymization needed for purchase/reconciliation or moderation records, clears
local database/preferences/notification schedules/secure state, and signs you
out. If you cannot use the app, use the separate public account-deletion page:
**[PUBLIC ACCOUNT-DELETION URL]**.

Deletion does not erase information that the operator is legally required to
retain or must retain for fraud, financial reconciliation, security, or abuse
prevention. Such records must be minimized, unlinked from the deleted account
where feasible, and retained only for the approved period stated above.

## Your choices

You may decline optional camera, microphone, notification, AI, sync, family,
referral, and purchase features. Android permission denial does not crash the
app. You may stop Sleep Safety, sign out, request account deletion, or contact
the privacy address above to ask a question about your data.

## Changes and contact

We will update the “Last updated” date when this policy changes. For privacy
questions or a deletion request, contact **[REAL SUPPORT EMAIL OR FORM URL]**.

## Publication checklist

Before entering this page in Google Play, the owner must:

1. replace every bracketed placeholder and name the legal entity;
2. confirm the actual AI, storage, analytics and observability providers;
3. approve retention periods and the deletion exceptions;
4. publish this as a public, non-login, HTTPS HTML page (not a repository or
   PDF URL);
5. set `PRIVACY_POLICY_URL` and `ACCOUNT_DELETION_URL` in the release public
   configuration and verify both links from Settings in the final AAB.
