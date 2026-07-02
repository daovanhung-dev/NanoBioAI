Commit de xuat: docs(checklist): tao checklist no ky thuat

# Checklist No Ky Thuat

## Metadata

| Field | Value |
|---|---|
| Snapshot | 2026-07-02 |
| Pham vi | Toan repo NanoBio Flutter app |
| Workflow | `.codex/workflows/docs-context.md` |
| Nguon bang chung | `.codex`, issue/todo hien co, `flutter analyze`, `flutter test`, format dry-run, targeted `rg` |
| Luu y an toan | Khong doc/in noi dung `.env`; chi kiem tra tracked/asset status. |

## Tom tat hien trang

- `flutter analyze`: FAIL - 97 issues, gom 2 compile/analyzer errors, warning asset folder thieu, Nabi import sai case, stale/deprecated/unused lint.
- `flutter test`: FAIL - 438 pass / 27 fail; cac fail gom Admin RPC mapping, stale widget text, migration compile error, Supabase quota contract, profile contract, onboarding overflow/dev banner.
- `dart format --output=none --set-exit-if-changed lib test`: FAIL - 21 Dart files can format.
- `.env` dang tracked theo `git ls-files` va duoc khai bao asset trong `pubspec.yaml`.
- Supabase sandbox/RLS/provider/real-device evidence van la backlog san xuat, khong phai code-ready evidence.

## Checklist uu tien

| Done | Priority | Debt | Status | Evidence | Impact | Suggested next action | Existing issue/todo |
|---|---|---|---|---|---|---|---|
| [ ] | P0 | Secret/env handling: `.env` dang tracked va duoc dong goi asset | Open | `git ls-files -- .env` tra ve `.env`; `.gitignore:9` ignore `.env`; `pubspec.yaml:65` khai bao `- .env` | Secret hoac config local co the vao VCS/app bundle; vi pham rule khong commit secret. | Tao issue rieng; remove `.env` khoi tracking, thay asset `.env` bang cau hinh an toan/flavor, rotate keys neu da tung commit secret; khong in noi dung `.env`. | New |
| [ ] | P1 | Release gate: analyzer fail | Open | `flutter analyze`: 97 issues; errors tai `test/core/storage/localdb/migration_manager_test.dart:448`, `:467`; import sai case `lib/app_versions/v1/features/nabi/presentation/widgets/nabi_floating_overlay.dart:9`; asset warnings `pubspec.yaml:68-117` | Khong dat release hygiene; compile/test discovery bi chan boi contract stale. | Fix compile errors truoc, sau do batch lint theo module: Nabi import/case, asset manifest, unused/deprecated UI warnings. | `docs/issues/release-analyze-red-290-issues/001-issue-release-analyze-red-290-issues.md`, `docs/todo/release-analyze-red-290-issues/001-todo-release-analyze-red-290-issues.md` |
| [ ] | P1 | Release gate: full test suite fail | Open | `flutter test`: 438 pass / 27 fail | Khong the claim release-ready; mot so contract docs/code/test dang lech. | Tach fix theo cum fail: Admin RPC, stale widget text, migration test compile, Supabase quota contract, profile contract, onboarding layout/dev banner. | `docs/issues/release-test-suite-fails/001-issue-release-test-suite-fails.md`, `docs/todo/release-test-suite-fails/001-todo-release-test-suite-fails.md` |
| [ ] | P1 | Format hygiene drift | Open | `dart format --output=none --set-exit-if-changed lib test`: 21 files would change | Lam nhiem diff cac phien sau va co the chan CI/dry-run release. | Chay format trong mot fix-only phien, verify diff chi format. | `docs/issues/release-format-dry-run-fails-new-pages/001-issue-release-format-dry-run-fails-new-pages.md`, `docs/todo/release-format-dry-run-fails-new-pages/001-todo-release-format-dry-run-fails-new-pages.md` |
| [ ] | P1 | Admin RPC/action contract drift | Open | `test/app_versions/admin/admin_models_test.dart:256`, `:276`, `:353`; expected `admin_create_reconciliation_run`, `admin_refund_or_cancel_payment`, `admin_list_report_catalog` nhung actual mapping khac trong test output | Admin payment/reconciliation/report actions co the goi sai RPC hoac test contract da stale; anh huong dashboard Admin va finance ops. | Doi chieu DD/Admin SQL contract voi `admin_models.dart`; chot source-of-truth RPC mapping roi update code/test/docs dong bo. | New |
| [ ] | P1 | SQLite/cloud sync migration test compile error | Open | `test/core/storage/localdb/migration_manager_test.dart:448`, `:467` goi `SyncOutboxSchema.personalScheduleAiRequestsTable`; `lib/core/storage/localdb/sync/sync_outbox_schema.dart:9` khong expose getter do | Migration suite khong load duoc; cloud-sync personal schedule request coverage bi mat. | Them contract getter hoac update test theo schema moi; chay targeted migration/sync tests. | New |
| [ ] | P1 | Stale widget text contracts after Vietnamese copy update | Open | Tests expect ASCII text: health scoring `Can dang nhap`, `Chua co lich su cham soc`, `Thanh phan diem`; app renders `Cần đăng nhập`, `Chưa có lịch sử chăm sóc`, `Thành phần điểm`. FamilyPlus test expects `Danh cho FamilyPlus`, `Quan ly gia dinh`; app renders `Dành cho FamilyPlus`, `Quản lý gia đình`. Profile contract expects `label: 'Email'`; app has `label: 'Địa chỉ email'`. | False-negative tests hide real regressions and slow release validation. | Update tests to assert keys/semantics or exact current Vietnamese copy; avoid mojibake/ASCII drift. | New |
| [ ] | P1 | Onboarding welcome layout overflow and dev banner test drift | Open | `flutter test` reports RenderFlex overflow at `lib/app_versions/v1/features/onboarding/presentation/widgets/welcome_step.dart:159`, `:192`; `test/widget_test.dart:96`, `:121`, `:155` fail around `onboarding_ai_dev_check_banner` and mobile layout | Mobile onboarding first screen can overflow and tests fail before checking intended states. | Make welcome hero responsive/scroll-safe; decide whether AI dev banner is still expected, then update UI or tests. | New |
| [ ] | P1 | Architecture violations remain documented as unfixed | Tracked | `test/ARCHITECTURE_VIOLATIONS_COUNTEREXAMPLES.md`; `test/architecture_violation_exploration_test.dart` checks cross-feature dependency, service->feature dependency, datasource naming, nested feature, misplaced model | Feature boundaries and dependency direction remain fragile; future changes risk widening coupling. | Convert counterexamples into fix-issue todos one by one; keep architecture preservation tests passing after each refactor. | New |
| [ ] | P1 | Nabi visual state import case mismatch | Open | `lib/app_versions/v1/features/nabi/presentation/widgets/nabi_floating_overlay.dart:9` imports `../../domain/Nabi_visual_state.dart`; canonical file is `nabi_visual_state.dart`; analyzer reports constant pattern never matches | Potential platform/case-sensitive build issue and wrong enum type comparison. | Normalize import/file casing and rerun targeted Nabi tests plus analyzer. | New |
| [ ] | P1 | AI raw prompt/response/health data logging | Tracked | `docs/issues/ai-raw-payload-logging/001-issue-ai-raw-payload-logging.md`; `lib/app_versions/v1/services/ai/ai_service.dart:288`, `:970-989`; `test/services/ai/ai_service_test.dart:477` | Health/profile context can be exposed in debug logs. | Replace raw payload logs with safe summary metadata; update tests to assert no raw prompt/response/health data. | `docs/todo/ai-raw-payload-logging/001-todo-ai-raw-payload-logging.md` |
| [ ] | P1 | Onboarding sensitive summary/logging | Tracked | `docs/issues/onboarding-sensitive-snapshot-logging/001-issue-onboarding-sensitive-snapshot-logging.md`; `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart:522-524`, `:571`, `:610` | User health/profile/session summaries may leak into logs. | Sanitize or remove onboarding summary logs; keep only counts/safe event names. | `docs/todo/onboarding-sensitive-snapshot-logging/001-todo-onboarding-sensitive-snapshot-logging.md` |
| [ ] | P1 | Supabase sandbox/RLS/provider evidence missing | Needs verification | `.codex/history/OPEN_RISKS.md:5-12`; `docs/checklist/checklist_task_coding.md:23-33` | Membership, quota, FamilyPlus, sale/referral, payment, Admin, RLS cannot be called production-ready. | Run Supabase local/sandbox smoke for two users/family scopes and provider/payment/Admin audit flows; record acceptance evidence. | Existing open risk `NB-RISK-001` |
| [ ] | P2 | Pubspec asset manifest references missing directories | Open | `flutter analyze` and `flutter test` report missing asset directories; `pubspec.yaml:68-117` includes many empty/missing folders | Noisy builds/tests; real asset packaging problems can be missed. | Either restore intended asset dirs with tracked placeholders or remove unused asset entries. | New |
| [ ] | P2 | Planned module scaffolds still present | Accepted/planned | `rg` finds `status = 'planned'` in `personal_schedule_quota`, v3 premium/goal/family modules, sale payment events | Future agents may confuse planned stubs with implemented product behavior. | Keep planned marker until implementation starts; link each planned module to DD/evidence checklist. | Existing DD/checklist context |
| [ ] | P2 | UI loading skeleton/shimmer TODO | Open | `lib/core/theme/primitives/states/loading_state.dart:126`, `:129` | Design system exposes placeholder visual modes without real skeleton/shimmer behavior. | Decide whether to implement skeleton/shimmer or remove variants from public primitive API. | New |
| [ ] | P2 | Admin log export TODO | Open | `lib/app_versions/admin/core/admin_logger.dart:223` | Admin audit/debug logs may lack export path for support/ops evidence. | Decide export requirement and privacy filters before implementation. | New |
| [ ] | P2 | Dependency drift | Open | `flutter analyze`/`flutter test` report 76 packages have newer versions incompatible with constraints | Upgrade backlog may hide deprecations/API breaks, especially Flutter/Riverpod/Supabase/local notifications. | Create dependency upgrade audit; prioritize security/platform packages and run targeted regression tests. | New |

## Suggested fix order

1. P0 `.env` tracking/asset packaging, because it is a security debt and may require key rotation.
2. Analyzer compile blockers: `SyncOutboxSchema.personalScheduleAiRequestsTable` and Nabi import case.
3. Format-only batch for the 21 Dart files.
4. Admin/Supabase/profile contract drift, because these are static contract failures.
5. Stale widget text and onboarding overflow/dev banner tests.
6. Logging/privacy todos for AI and onboarding.
7. Supabase sandbox/RLS/provider evidence backlog.
8. Architecture counterexamples and planned/TODO cleanup.

## Follow-up workflow

- Use `fix-issues` for one documented issue/todo at a time.
- For new rows marked `New`, create issue docs first through `create-issues` before fixing.
- For Supabase behavior changes, follow `.codex/workflows/supabase-schema.md` and update `docs/supabase/config.sql` when schema/RLS/RPC changes.
- After each substantial fix, create/update worklog and run `.codex/tools/update_worklog_learning.ps1`.
