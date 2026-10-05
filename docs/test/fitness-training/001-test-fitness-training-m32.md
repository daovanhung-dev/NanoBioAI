Commit de xuat: docs(test): ghi nhan kiem thu M32 pilot

# Test report — M32 Chế độ luyện tập pilot

## Phạm vi

Kiểm tra source M32 được PO chỉ đạo nối vào FeatureHub: local age gate, catalog filters, giới hạn response Gemini, quota/idempotency, SQLite program/schedule transaction, FeatureHub/router integration và Edge operation allowlist.

## Kết quả

| Check | Result | Coverage / limit |
|---|---|---|
| Targeted `flutter analyze` on 17 M32, route, sync, database and test targets | PASS — no issues found | Static Dart analysis only. |
| Focused Flutter tests: M32, FeatureHub entry, route guards and FeatureHub page | PASS — 28/28 | Includes age boundary, catalog inventory and filtering, DOB exclusion from AI intake, strict JSON schema/ID checks, member and Guest quota stops, request reuse, DB migration, future schedule replacement, no same-day past-time reinsert, completion/history preservation and UI disclosure/accessibility label. |
| `deno test supabase/functions/nabi-ai-generate/handler_test.ts` | PASS — 12/12 | Operation allowlist, request/response bounds, rate limit, provider failure handling. No live Gemini request. |
| Existing M05 sync/outbox contract suites | PASS — 16/16 | Cloud/local table contract, authenticated sync repository, SQLite ownership proof and sync outbox retry behavior. No Supabase call. |
| `flutter build apk --debug` | PASS | Android package build only; no install or physical-device interaction. |
| `flutter build apk --release` | PASS — initial Android release APK built (154.8 MB, all configured ABIs) | Packaging verification only; no install or publishing. This universal package predates the final same-day schedule guard; final source was rebuilt in the split-per-ABI command below. |
| `flutter build apk --release --split-per-abi` | PASS after final same-day schedule guard | APKs built for armeabi-v7a, arm64-v8a and x86_64 (about 99–103 MB per ABI). |
| Catalog/reference integrity script | PASS | Counts 24/16 gym/8 home, 10 equipment, 35 recipes and 47 ingredients; FDC IDs and ingredient/image/atlas references resolve; runtime catalog matches the review pack. |

Focused Flutter command:

```sh
LD_LIBRARY_PATH=/tmp/nanobio_m32_sqlite_lib /home/daovanhung/development/Flutter/flutter/bin/flutter test \
  test/app_versions/v1/features/fitness_training \
  test/app_versions/v1/features/features_hub/fitness_training_feature_entry_test.dart \
  test/app_versions/v1/router/v1_route_guards_test.dart \
  test/features/features_hub/features_hub_page_test.dart
```

The temporary `LD_LIBRARY_PATH` resolves the host's installed `libsqlite3.so.0` for Flutter's SQLite test dependency; it is not app configuration.

M05 snapshot/sync command:

```sh
LD_LIBRARY_PATH=/tmp/nanobio_m32_sqlite_lib /home/daovanhung/development/Flutter/flutter/bin/flutter test \
  test/app_versions/v2/features/cloud_sync/cloud_sync_contract_test.dart \
  test/app_versions/v2/features/cloud_sync/authenticated_user_data_sync_repository_test.dart \
  test/app_versions/v2/features/cloud_sync/sqlite_user_data_sync_proof_test.dart \
  test/services/supabase/cloud_sync/user_data_sync_outbox_test.dart
```

## Not verified

- No live Gemini call, API quota consumption or retry against a real Supabase project.
- Supabase SQL/RLS and M05 snapshot sync have not been applied to a sandbox.
- No APK install/manual M32 navigation on the connected Android handset; the installed app shares the user package/data, so this session avoided replacing it without an isolated QA device/account.
- No iOS/Xcode build or iPhone test is available in this Linux environment.
- YouTube candidates have no approved embed IDs; the fallback is covered at source/UI level, while actual IFrame success/failure remains Android/iOS QA work.
- FamilyPlus dependent-subject program selection/storage/sync is not implemented in this pilot.
- Tech/Privacy, Clinical and QA sign-offs remain pending. Catalog/nutrition candidates remain under review; this report is not release approval.
