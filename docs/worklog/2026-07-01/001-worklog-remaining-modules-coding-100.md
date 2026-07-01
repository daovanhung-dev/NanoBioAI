Commit de xuat: feat(modules): hoan tat coding cac module con lai

# Worklog - Remaining modules coding 100 percent

## Thoi gian

- Ngay: 2026-07-01
- Bat dau: 09:30
- Ket thuc: 11:20
- Timezone: Asia/Saigon (+07:00)

## Pham vi

- Loai task: coding
- Module chinh: M02 `PERSONAL_SCHEDULE_AI`, M05 `AUTH_PROFILE_SYNC`, M06 `MEMBERSHIP_QUOTA`, M07 `AI_CHAT`, M11 `FAMILYPLUS`, M12 `REFERRAL_DIRECT`, M16 `ADMIN_OPS`, M17 `RECONCILIATION`, M18 `REPORTING`, M19 `AUDIT_SECURITY`
- Yeu cau goc: Implement plan dua tat ca module con lai len Coding progress 100% theo code + SQL/static contracts + targeted tests, khong claim sandbox/staging production evidence.

## Da lam

- M11: them v3 FamilyPlus runtime slice gom models, repository, Supabase datasource, providers, page va route `/v3/familyplus`; them SQL/RPC `get_my_familyplus_context`, `upsert_my_familyplus_group`, `upsert_my_familyplus_member`, `remove_my_familyplus_member`; enforce active `family_plus`, owner-managed writes, max 5 active members, idempotency key, safe errors va selected subject context.
- M02/M06/M07: harden quota contracts cho Free `ai_chat_message` 3/day, Free `personal_schedule_generation` 3/month, Plus/FamilyPlus bypass, `Asia/Ho_Chi_Minh` period keys, idempotent commit, no client writes; personal schedule commit denial map ve quota exception an toan.
- M05: them SQLite v12 va cloud-sync mapping cho `personal_schedule_ai_requests`, gom migration, snapshot table config, outbox marker/drain theo `request_id`, retry path va Supabase snapshot contract.
- M12: them referral attach static contract tests cho registration-only source va anti-fraud blockers: self-referral, duplicate relationship, inactive Sale, device/email/phone collision, payment-history lock.
- M16-M19: cap nhat Admin action mapping cho payment reversal `refund`/`cancel`/`chargeback`, reconciliation `create_run`, safe report catalog/export, fixed report types, privacy-limited filters/timezone, reason/idempotency va audit/no-raw-payload contracts.
- Cap nhat `docs/checklist/checklist_complete_DD.md` va `docs/checklist/checklist_task_coding.md` de M01-M19 deu hien Coding progress 100%, trong khi sandbox/RLS/provider/audit evidence van nam o production backlog.

## File code/docs da sua

- `lib/app_versions/v3/features/familyplus/` - tao - runtime FamilyPlus slice.
- `lib/app_versions/v3/router/` - sua - route `/v3/familyplus`.
- `lib/app_versions/v3/features/family_members/`, `family_onboarding/`, `family_schedule/` - sua - status metadata sang implemented va tro ve FamilyPlus route.
- `lib/core/storage/localdb/` va `lib/services/supabase/cloud_sync/` - sua - SQLite v12/outbox/cloud sync cho schedule AI request.
- `lib/app_versions/v2/features/cloud_sync/data/datasources/` - sua - sync table mapping va Supabase upsert theo `request_id`.
- `lib/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart` - sua - commit quota denial handling.
- `lib/app_versions/admin/features/admin_panel/` - sua - Admin RPC/action/report/reconciliation mapping.
- `docs/supabase/` - sua - FamilyPlus RPC, schedule AI request snapshot sync, Admin report catalog/export/audit contracts.
- `test/` - sua/tao - FamilyPlus, quota, cloud-sync, referral, Admin, docs contract va architecture tests.
- `docs/checklist/` - sua - Coding progress/backlog.
- `.codex/AGENTS.md`, `.codex/README.md`, `.codex/domains/sqlite.md` - sua - SQLite snapshot version va v3 status context.

## Tai lieu lien quan

- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `.codex/domains/access-membership-referral.md`
- `.codex/domains/sqlite.md`
- `.codex/domains/ai-service.md`
- `docs/checklist/checklist_complete_DD.md`
- `docs/checklist/checklist_task_coding.md`
- `docs/supabase/README.md`

## Commands

- `dart format <touched Dart and test files>`: PASS.
- `flutter analyze <touched lib/test files>`: PASS - No issues found.
- `flutter analyze lib/app_versions/v3/features/familyplus test/app_versions/v3/features/familyplus`: PASS - No issues found after final subject-context hardening.
- `flutter test test/app_versions/v3/features/familyplus/domain/familyplus_models_test.dart test/app_versions/v3/features/familyplus/data/familyplus_repository_test.dart test/app_versions/v3/features/familyplus/providers/familyplus_providers_test.dart test/app_versions/v3/features/familyplus/presentation/familyplus_page_test.dart`: PASS - 13 tests passed.
- `flutter test test/core/storage/localdb/migration_manager_test.dart test/services/supabase/cloud_sync/user_data_sync_outbox_test.dart test/app_versions/v2/features/cloud_sync/cloud_sync_contract_test.dart`: PASS.
- `flutter test test/services/supabase/usage_quota_gateway_test.dart test/docs/supabase_config_contract_test.dart test/docs/supabase_admin_contract_test.dart test/app_versions/admin/admin_models_test.dart test/app_versions/v1/features/ai_chat/ai_chat_quota_test.dart test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart test/sale_referral/data/sale_repository_impl_test.dart test/sale_referral/domain/sale_models_test.dart`: PASS.
- `flutter test test/architecture_version_boundary_test.dart`: PASS - 9 tests passed.
- `git diff --check`: PASS.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: PASS - CODEX INTEGRITY VALIDATION PASSED.

## Loi/Rui ro

- Da fix: FamilyPlus route/runtime gap, placeholder metadata, missing schedule AI request cloud-sync mapping, quota commit denial handling, referral anti-fraud contract coverage, Admin payment/reconciliation/report/audit mapping gaps.
- Chua fix: Flutter commands van in warning asset folder thieu tu `pubspec.yaml`; day la baseline warning va command exit 0.
- Khong chay: live Supabase sandbox/service-role/RLS/provider smoke do moi truong hien tai khong co DB/service-role connection. Cac muc nay van nam trong production evidence backlog.

## Ty le hoan thanh

- Hoan thanh: M02/M05/M06/M07/M11/M12/M16/M17/M18/M19 coding 100% theo code + SQL/static contracts + targeted tests.
- Dang do: production-readiness sandbox/RLS/provider/audit/retention/real-device evidence ngoai acceptance scope hien tai.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - thay doi rong nhung tach theo module, giu layer boundary, dong bo Dart/SQL/docs contracts va tests.
- Muc do hoan thanh task: hoan thanh coding acceptance cho tat ca module con lai; khong claim sandbox/production acceptance.
- Bang chung kiem chung: targeted format pass, targeted analyze pass, focused FamilyPlus/M05/quota/Admin/Sale/docs tests pass, architecture boundary pass, diff check pass, Codex integrity pass.
- Diem ton token/chua toi uu: pham vi rat rong nen can doc nhieu diff va test output; can them index nho cho checklist module status de giam `rg`/doc lai.
- Cach toi uu cho phien sau: chay production evidence theo tung cum sandbox, uu tien Supabase service-role/RLS smoke va provider payment/reconciliation evidence thay vi mo lai code runtime.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
