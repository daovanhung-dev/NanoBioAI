# Release evidence matrix

| Gate | Evidence in repository | Status |
| --- | --- | --- |
| Play Billing consumer path | Store product/domain/repository/controller/widget tests; resolved `com.android.billingclient:billing:8.0.0` | SOURCE/DEPENDENCY PASS; internal purchase OPEN |
| Trusted entitlement grant | Edge handler tests + canonical RPC/static contract | SOURCE PASS; sandbox replay OPEN |
| AI report action | report entity/controller/sheet + widget tests | SOURCE PASS; deployed function OPEN |
| AI provider secret isolation | no Android BuildConfig/MethodChannel; backend client/function; final arm64 strings scan has no key marker or provider URL | SOURCE/ARTIFACT PASS; deployed secret/runtime OPEN |
| API/target 36 | `android/app/build.gradle.kts`; release AAB built | SOURCE/ARTIFACT PASS |
| Broad photo permission | manifest removed; picker uses system picker | SOURCE PASS; device policy review OPEN |
| Health-claim/catalog eligibility | `MealCandidateSelector` filters `isPlanEligible`; formatter suppresses unreviewed claim fields; focused tests | SOURCE PASS; catalog/content review OPEN |
| Account deletion full lifecycle | `delete-account` removes `schedule-completion-proofs` objects before Auth deletion; Flutter clears SQLite, preferences, notification schedules and secure storage, then signs out; handler/account contract tests | SOURCE PASS; sandbox deletion + two-session isolation OPEN |
| Public privacy/account-deletion URLs | Publish-ready Privacy Policy and deletion page; Settings links require valid HTTPS `PRIVACY_POLICY_URL`/`ACCOUNT_DELETION_URL` | SOURCE READY; public HTTPS page BLOCKED_EXTERNAL |
| Supabase rebuild/RLS/deletion | canonical SQL + rollback smoke fixture | STATIC ONLY; runtime OPEN |
| Foreground mic | manifest and existing sleep-safety implementation | MANUAL OPEN |
| 16 KB page size | AAB native ELF segments checked (0x4000/0x10000); no device install test | ARTIFACT PASS; MANUAL OPEN |
| Release signing / Play App Signing | release variant built with the local signing configuration available; Play Console/App Signing access not evidenced | LOCAL BUILD PASS; Play Console BLOCKED |
| Data Safety / Health Apps forms | mapping and declaration drafts; no submission evidence | PREPARED; Console/legal review OPEN |
| Targeted Flutter validation | Release-focused contract tests for Billing, purchase verification, account deletion, AI reporting, Sleep Safety, notifications, Supabase, env/secret isolation and meal eligibility pass; SQLite-backed tests pass with the installed `libsqlite3.so.0` exposed under the expected test name. Full suite under the same test-only alias reaches `1144 PASS / 79 FAIL` and times out during teardown; the remaining failures are not all release-gate contracts. | TARGETED PASS; FULL SUITE NO-GO |
| Final AAB | `build/app/outputs/bundle/release/app-release.aab`; 2026-09-01 04:40 +07; SHA-256 `dbcf473c27d27ab36fe5dd130170dbba287609538cf4ec32866c41b992eb22ee`; 128,427,356 bytes; target/compile 36; package `com.nanobioai.app`; version `1.0.0` / versionCode `1` | LOCAL ARTIFACT PASS; Play App Signing OPEN |
| Final ZIP | `docs/release/google_play/NanoBioAI_GOOGLE_PLAY_FINAL_PASS_SOURCE_READY_20260901.zip`; changed-file allowlist only; excludes caches, build outputs, secrets, logs and the user-provided plan | LOCAL PACKAGE PASS; RELEASE VERIFY OPEN |
