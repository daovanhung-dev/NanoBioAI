Commit de xuat: feat(m02): hoan thien runtime guard lich trinh ca nhan

# Worklog - M02 Runtime Guard

## Thoi gian

- Ngay: 2026-06-29
- Bat dau: khong ghi nhan chinh xac
- Ket thuc: khong ghi nhan chinh xac
- Timezone: Asia/Saigon

## Pham vi

- Loai task: coding/test/docs
- Module chinh: M02 PERSONAL_SCHEDULE_AI
- Yeu cau goc: Implement plan "Hoan Thanh M02 Runtime Guard".

## Da lam

- Them SQLite v10: `personal_schedule_ai_requests` va `users.guest_initial_plan_used`.
- Doi `GeneratedPlanService` sang request-based flow co `requestId`, idempotent retry, guest one-time guard va failed request record.
- Them `PersonalScheduleQuotaGateway` cho member generation: check truoc AI, commit sau transaction thanh cong; trusted backend production van blocked neu RPC chua san sang.
- Generate meal/exercise/schedule truoc, validate schedule, roi commit meal + schedule + request result + guest flag trong mot transaction local.
- Dashboard generate additional plan chuyen sang append sau lich hien co va truyen idempotency key.
- Map safe error cho quota unavailable/exceeded va guest initial plan used.
- Them targeted tests cho generated plan guard, quota guard, migration v10 va dashboard append contract.

## File code/docs da sua

- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - sua - request/idempotency/quota guard.
- `lib/app_versions/v1/services/ai/generated_plan_request_store.dart` - tao - local request ledger/transaction commit.
- `lib/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart` - tao - quota interface va trusted backend adapter boundary.
- `lib/core/storage/localdb/*` - sua/tao - SQLite v10 schema.
- `lib/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart` - sua - append generation va request id.
- `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart` - sua - safe quota/guest errors.
- `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart` - sua - safe guest-used error.
- `test/**` - sua/tao - targeted generated plan, migration va dashboard contract tests.
- `docs/checklist/*.md` - sua - cap nhat tien do M02 va blocker con lai.

## Tai lieu lien quan

- `docs/DD/personal_schedule_ai/`
- `docs/checklist/checklist_complete_DD.md`
- `docs/checklist/checklist_task_coding.md`
- `docs/checklist/checklist_develop_DD.md`

## Commands

- `dart analyze lib/app_versions/v1/services/ai/generated_plan_service.dart lib/app_versions/v1/services/ai/generated_plan_request_store.dart lib/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart`: PASS
- `dart analyze lib/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart`: PASS
- `dart analyze lib/core/storage/localdb/database_service.dart lib/core/storage/localdb/migrations/migration_manager.dart lib/core/storage/localdb/tables/users_table.dart lib/core/storage/localdb/tables/personal_schedule_ai_requests_table.dart`: PASS
- `dart analyze test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart`: PASS
- `flutter test test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart`: PASS
- `flutter test test/core/storage/localdb/migration_manager_test.dart`: PASS
- `flutter test test/app_versions/v1/features/dashboard/dashboard_generated_plan_contract_test.dart`: PASS
- `flutter test test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart`: PASS
- `flutter test test/app_versions/v1/features/onboarding/onboarding_local_datasource_test.dart`: PASS
- `flutter test test/features/lifestyle_schedule/data/lifestyle_schedule_dao_test.dart test/features/lifestyle_schedule/data/lifestyle_schedule_completion_test.dart`: PASS
- `powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1`: FAIL - script stopped at `dart format --set-exit-if-changed .` after formatting files; unrelated formatter churn was reverted, touched M02 files kept formatted, targeted analyze/tests reran PASS.

## Loi/Rui ro

- Da fix: guest initial generation khong con phu thuoc auth; guest tao lai bi chan truoc AI; member quota denied bi chan truoc AI; AI fail khong commit quota/request success.
- Chua fix: trusted M06 quota RPC/RLS sandbox chua co, nen production adapter mac dinh fail-safe khi backend contract chua san sang.
- Can kiem tra tiep: Q-16 timezone approval, FamilyPlus subject/ownership, Supabase acceptance evidence.

## Ty le hoan thanh

- Hoan thanh: M02 runtime local guard va targeted tests.
- Dang do: production trusted quota backend va FamilyPlus subject-aware flow.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - implemented dung plan runtime va giu blocker production ro rang.
- Muc do hoan thanh task: runtime scope hoan thanh; backend production con blocked theo DD.
- Bang chung kiem chung: targeted analyze/test PASS nhu Commands.
- Diem ton token/chua toi uu: test fixture trong generated plan file kha dai.
- Cach toi uu cho phien sau: tach fake helpers neu tiep tuc mo rong M02/M06 tests.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
