Commit de xuat: feat(quota): wire trusted quota gateway cho AI chat

# Worklog - Quota AI Chat Foundation

## Thoi gian

- Ngay: 2026-06-30
- Bat dau: 14:50
- Ket thuc: 15:06
- Timezone: Asia/Saigon

## Pham vi

- Loai task: coding
- Module chinh: M06 `MEMBERSHIP_QUOTA`, M07 `AI_CHAT`, M02 `PERSONAL_SCHEDULE_AI`
- Yeu cau goc: Implement plan coding hoan tat DD modules M01-M19; bat dau tu quota/access foundation va AI Chat quota gate.

## Da lam

- Them shared quota gateway `TrustedBackendUsageQuotaGateway` dung Supabase RPC injectable, co `UsageQuotaDecision`, feature key, exception user-safe va test fake RPC.
- Them v2 `EffectiveAccess` read model/repository/provider doc tu view `effective_user_access`.
- Wire AI Chat repository de check quota truoc khi goi AI va commit quota chi sau khi co response thanh cong.
- Map loi quota/auth/unavailable sang copy Vietnamese an toan trong AI Chat controller.
- Dong bo Supabase quota SQL: `check_usage_quota`, `commit_usage_quota`, `check_personal_schedule_generation_quota`, `commit_personal_schedule_generation_quota`, grant execute, idempotency theo `p_request_id`, timezone `Asia/Ho_Chi_Minh`.
- Cap nhat acceptance checklist Supabase va DD coding checklist cho M02/M06/M07.
- Xoa stale generated open-risk path cho Q-01..Q-10 trong history refresh script vi DD decisions Q-01..Q-18 da approved.

## File code/docs da sua

- `lib/services/supabase/usage_quota/usage_quota_gateway.dart` - tao moi - shared quota RPC gateway.
- `lib/app_versions/v1/features/ai_chat/domain/repositories/ai_chat_repository_impl.dart` - sua - check/commit quota quanh AI call.
- `lib/app_versions/v1/features/ai_chat/presentation/controllers/ai_chat_controller.dart` - sua - map loi quota sang UI copy an toan.
- `lib/app_versions/v1/features/ai_chat/providers/ai_chat_providers.dart` - sua - inject quota gateway.
- `lib/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart` - sua - timezone quota `Asia/Ho_Chi_Minh`.
- `lib/app_versions/v2/features/usage_quota/usage_quota.dart` - sua - runtime quota facade.
- `lib/app_versions/v2/features/membership_entitlement/` - tao moi - effective access read model/repository/provider.
- `docs/supabase/03-membership-quota.sql`, `docs/supabase/config.sql`, `docs/supabase/07-seed-reference-data.sql` - sua - trusted quota RPCs va timezone.
- `docs/supabase/08-acceptance-checks.md` - sua - sandbox quota acceptance cases.
- `test/services/supabase/usage_quota_gateway_test.dart`, `test/app_versions/v1/features/ai_chat/ai_chat_quota_test.dart`, `test/docs/supabase_config_contract_test.dart` - tao/sua - coverage cho quota gateway, AI Chat gate, Supabase contract.
- `docs/checklist/checklist_complete_DD.md`, `docs/checklist/checklist_task_coding.md` - sua - tien do/evidence M02/M06/M07.
- `.codex/tools/update_worklog_learning.ps1` - sua - khong regenerate stale Q-01..Q-10 open blocker.

## Tai lieu lien quan

- `docs/DD/README.md`
- `docs/checklist/checklist_complete_DD.md`
- `docs/checklist/checklist_task_coding.md`
- `docs/supabase/README.md`
- `docs/supabase/08-acceptance-checks.md`

## Commands

- `dart format ...`: PASS - format cac Dart file touched.
- `flutter test test\services\supabase\usage_quota_gateway_test.dart test\app_versions\v1\features\ai_chat\ai_chat_quota_test.dart test\docs\supabase_config_contract_test.dart test\app_versions\v1\services\ai\generated_plan_service_auth_test.dart`: PASS - 26 tests pass; Flutter van in asset directory warnings do nhieu asset folders dang bi xoa san trong worktree.
- `dart analyze lib\services\supabase\usage_quota\usage_quota_gateway.dart lib\app_versions\v2\features\membership_entitlement lib\app_versions\v2\features\usage_quota\usage_quota.dart lib\app_versions\v1\features\ai_chat\domain\repositories\ai_chat_repository_impl.dart lib\app_versions\v1\features\ai_chat\providers\ai_chat_providers.dart lib\app_versions\v1\features\ai_chat\presentation\controllers\ai_chat_controller.dart test\services\supabase\usage_quota_gateway_test.dart test\app_versions\v1\features\ai_chat\ai_chat_quota_test.dart`: PASS - no issues found.
- `flutter test test\architecture_version_boundary_test.dart`: PASS - 9 tests pass; same pre-existing asset directory warnings.
- `git diff --check`: PASS - whitespace diff clean.
- `powershell -ExecutionPolicy Bypass -File .codex\tools\validate_codex_integrity.ps1`: FAIL - stale asset paths because many asset folders/files are currently deleted in worktree outside this quota slice.

## Loi/Rui ro

- Da fix: Flutter/SQL RPC mismatch cho personal schedule quota; AI Chat truoc day chua gate quota truoc AI call.
- Chua fix: Chua co Supabase sandbox/staging execution evidence cho quota RPC/RLS/counter idempotency/client write rejection.
- Can kiem tra tiep: Run `docs/supabase/config.sql` trong sandbox va check Free 3/day AI chat, Free 3/month schedule, Plus/FamilyPlus bypass, duplicated `p_request_id`, client write rejection; quyet dinh khoi phuc hay cap nhat docs/pubspec cho asset folders dang bi xoa.

## Ty le hoan thanh

- Hoan thanh: M06/M07/M02 foundation code/test/SQL contract.
- Dang do: Production acceptance cho M01-M19 van can sandbox/RLS/API/audit evidence va cac module con lai theo checklist.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - thay doi scoped vao quota/access/AI Chat, co test va khong pha boundary v1/v2.
- Muc do hoan thanh task: partial - implement duoc foundation quan trong cua plan, nhung khong the claim tat ca module 100% khi chua co sandbox/staging evidence.
- Bang chung kiem chung: targeted tests/analyze/architecture/git diff check pass; `.codex` integrity fail do asset paths bi xoa san; SQL sandbox chua chay.
- Diem ton token/chua toi uu: request M01-M19 qua rong nen can tiep tuc theo vertical slice va checklist thay vi doc toan bo DD/source.
- Cach toi uu cho phien sau: bat dau bang Supabase sandbox quota acceptance, sau do M11 FamilyPlus subject/RLS vi no mo khoa M03/M08/M09/M10.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
