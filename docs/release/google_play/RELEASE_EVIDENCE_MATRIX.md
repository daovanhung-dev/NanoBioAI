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
| Release signing / Play App Signing | locally signed AAB; Play Console/App Signing access not evidenced | LOCAL ARTIFACT PASS; Play Console BLOCKED |
| Data Safety / Health Apps forms | mapping and declaration drafts; no submission evidence | PREPARED; Console/legal review OPEN |
| Targeted Flutter validation | Remediation contract tests for Billing, purchase verification, account deletion, AI reporting, Sleep Safety, notifications, Supabase, env/secret isolation, meal eligibility and raw logging pass; SQLite DAO checks pass with the installed `libsqlite3.so.0` exposed under the expected test name; baseline full suite reaches 978 passes but retains 236 failures and one shutdown stream error | TARGETED PASS; FULL SUITE NOT CLEAN |
| Final AAB | `build/app/outputs/bundle/release/app-release.aab`; 2026-08-29; SHA-256 `94077ccc9b274369f342c05831579273ca2bfbfb55c86d09ddcae42dfff0830e`; 128,455,021 bytes; target/compile 36; local signer | LOCAL ARTIFACT PASS; Play App Signing OPEN |
| Final ZIP | `docs/release/google_play/NanoBioAI_GOOGLE_PLAY_REMEDIATION_20260829.zip`; generated after final diff audit and excludes caches, build outputs, secrets and the user-provided plan | LOCAL PACKAGE PASS |
