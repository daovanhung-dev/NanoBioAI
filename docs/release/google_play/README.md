# Google Play release evidence

This folder is the release handoff for the NanoBio Android build. It records
source-backed controls and keeps external gates explicit.

The companion drafts cover [Privacy Policy](PRIVACY_POLICY_PUBLIC_PAGE.md),
[Data Safety](DATA_SAFETY_MAPPING.md), [Health Apps declaration](HEALTH_APPS_DECLARATION.md),
[account deletion](ACCOUNT_DELETION.md), [foreground microphone](FOREGROUND_SERVICE_DECLARATION.md),
and [store listing claims](STORE_LISTING_CLAIMS_REVIEW.md).

## Implemented in source

- Billing uses Google Play product IDs from `StoreMembershipProduct`; no consumer
  VietQR checkout is reachable from `MembershipPaymentPage`; the resolved
  Android Billing dependency is `8.0.0`.
- Membership is updated only after `google-play-verify-purchase` verifies with
  Google and the service-role `finalize_google_play_purchase` RPC succeeds.
- AI generation routes through `nabi-ai-generate`; the Gemini credential is an
  Edge Function secret, not a Dart define, Gradle BuildConfig field, or Android
  MethodChannel value.
- New meal plans and replacements accept only reviewer-marked
  `isPlanEligible` catalog rows; unreviewed claim text is suppressed when an
  already persisted meal is displayed.
- Account deletion removes owned schedule-proof Storage objects before Auth
  deletion, and Settings exposes public privacy/deletion links when the release
  configuration supplies them.
- API/target SDK are explicitly 36.
- Gallery access uses the platform picker and the broad photo/media permissions
  were removed.

## External gates

The following require credentials, devices, or Play Console access and remain
open until evidence is attached:

- internal-track purchase with a real tester account and all four products;
- release-signed AAB and signing/Play App Signing metadata;
- Data Safety and Health Apps declarations submitted in Play Console;
- foreground microphone declaration and a device test;
- published HTTPS privacy/account-deletion pages plus final Data Safety/legal
  review;
- 16 KB page-size device/install verification;
- Supabase local/sandbox rebuild plus two-session RLS, replay, deletion and
  Edge Function runtime tests.

Latest local artifact check (2026-09-01, run `20260831T210948Z-a1ef0ed`):

- `flutter build appbundle --release` produced
  `build/app/outputs/bundle/release/app-release.aab` (128.4 MB; 128,427,356 bytes).
- SHA-256: `dbcf473c27d27ab36fe5dd130170dbba287609538cf4ec32866c41b992eb22ee`.
- Package is `com.nanobioai.app`, version `1.0.0` (versionCode `1`),
  minSdk `24`, compileSdk `36`, and targetSdk `36`.
- The release variant built with the local signing configuration available;
  the AAB itself is not evidence of Play App Signing. Its native ELF `LOAD`
  segments are aligned at
  0x4000 or 0x10000 for arm64-v8a, armeabi-v7a and x86_64 (no segment below
  16 KB).
- `strings` on the arm64 `libapp.so` contains the trusted `nabi-ai-generate`
  route marker and contains neither a Gemini API key marker nor the direct
  Google Generative Language provider URL. The provider URL remains confined
  to injected/test tooling and the Edge Function source.
- This does not prove Play App Signing, internal-track install, or a real
  16-KB Android device; those gates remain open.

Do not change these entries to PASS based only on static source inspection.

Policy references checked on 2026-09-01: [Play Billing deprecation
FAQ](https://developer.android.com/google/play/billing/deprecation-faq),
[Payments policy](https://support.google.com/googleplay/android-developer/answer/10281818),
[Target API policy](https://support.google.com/googleplay/android-developer/answer/11926878),
[Health apps declaration](https://support.google.com/googleplay/android-developer/answer/14738291),
[account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111),
[foreground-service requirements](https://support.google.com/googleplay/android-developer/answer/13392821),
[Data Safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469), and
[16 KB page-size guidance](https://developer.android.com/guide/practices/page-sizes).

The final repository-only handoff archive is
`docs/release/google_play/NanoBioAI_GOOGLE_PLAY_FINAL_PASS_SOURCE_READY_20260901.zip`.
It contains only the execution source/docs/test allowlist and excludes the
worklog runtime record, AAB, ignored signing material, caches, logs and the
user-provided plan document. Hash, size and extraction evidence are recorded in
the final worklog.
