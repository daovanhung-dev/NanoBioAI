# Google Play release evidence

This folder is the release handoff for the NanoBio Android build. It records
source-backed controls and keeps external gates explicit.

The companion drafts cover [Data Safety](DATA_SAFETY_MAPPING.md), [Health Apps
declaration](HEALTH_APPS_DECLARATION.md), [account deletion](ACCOUNT_DELETION.md),
[foreground microphone](FOREGROUND_SERVICE_DECLARATION.md), and [store listing
claims](STORE_LISTING_CLAIMS_REVIEW.md).

## Implemented in source

- Billing uses Google Play product IDs from `StoreMembershipProduct`; no consumer
  VietQR checkout is reachable from `MembershipPaymentPage`.
- Membership is updated only after `google-play-verify-purchase` verifies with
  Google and the service-role `finalize_google_play_purchase` RPC succeeds.
- AI generation routes through `nabi-ai-generate`; the Gemini credential is an
  Edge Function secret, not a Dart define, Gradle BuildConfig field, or Android
  MethodChannel value.
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
- 16 KB page-size device/install verification;
- Supabase local/sandbox rebuild plus two-session RLS, replay, deletion and
  Edge Function runtime tests.

Latest local artifact check (2026-08-28):

- `flutter build appbundle --release` produced
  `build/app/outputs/bundle/release/app-release.aab` (128.4 MB).
- Package is `com.nanobioai.app`, version `1.0.0` (versionCode `1`),
  minSdk `24`, compileSdk `36`, and targetSdk `36`.
- The AAB is locally signed by `CN=NanoBioAI, OU=Development, O=NanoBio,
  L=Hanoi, ST=Hanoi, C=VN`; its native ELF `LOAD` segments are aligned at
  0x4000 or 0x10000 (no segment below 16 KB).
- `strings` on the arm64 `libapp.so` contains the trusted `nabi-ai-generate`
  route marker and contains neither a Gemini API key marker nor the direct
  Google Generative Language provider URL.
- This does not prove Play App Signing, internal-track install, or a real
  16-KB Android device; those gates remain open.

Do not change these entries to PASS based only on static source inspection.

The final repository-only handoff archive is
`docs/release/google_play/NanoBioAI_GOOGLE_PLAY_REMEDIATION_20260828.zip`.
It excludes the AAB, ignored signing material, caches and the user-provided
plan document.
