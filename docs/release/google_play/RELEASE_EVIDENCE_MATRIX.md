# Release evidence matrix

| Gate | Evidence in repository | Status |
| --- | --- | --- |
| Play Billing consumer path | Store product/domain/repository/controller/widget tests | SOURCE PASS; internal purchase OPEN |
| Trusted entitlement grant | Edge handler tests + canonical RPC/static contract | SOURCE PASS; sandbox replay OPEN |
| AI report action | report entity/controller/sheet + widget tests | SOURCE PASS; deployed function OPEN |
| AI provider secret isolation | no Android BuildConfig/MethodChannel; backend client/function; final arm64 strings scan has no key marker/provider URL | SOURCE/ARTIFACT PASS; deployed secret/runtime OPEN |
| API/target 36 | `android/app/build.gradle.kts`; release AAB built | SOURCE/ARTIFACT PASS |
| Broad photo permission | manifest removed; picker uses system picker | SOURCE PASS; device policy review OPEN |
| Supabase rebuild/RLS/deletion | canonical SQL + rollback smoke fixture | STATIC ONLY; runtime OPEN |
| Foreground mic | manifest and existing sleep-safety implementation | MANUAL OPEN |
| 16 KB page size | AAB native ELF segments checked (0x4000/0x10000); no device install test | ARTIFACT PASS; MANUAL OPEN |
| Release signing / Play App Signing | locally signed AAB; Play Console/App Signing access not evidenced | LOCAL ARTIFACT PASS; Play Console BLOCKED |
| Data Safety / Health Apps forms | mapping and declaration drafts | OPEN |
| Targeted Flutter validation | 61 directly affected tests pass; full suite reaches 976 passes but retains 238 failures (legacy/environmental causes were observed; a clean baseline delta was not available) and one shutdown stream error | TARGETED PASS; FULL SUITE NOT CLEAN |
| Final ZIP | `docs/release/google_play/NanoBioAI_GOOGLE_PLAY_REMEDIATION_20260828.zip`; generated after final diff audit and excludes caches, build outputs, secrets and the user-provided plan | LOCAL PACKAGE PASS |
