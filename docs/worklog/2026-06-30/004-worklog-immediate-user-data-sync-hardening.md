Commit de xuat: feat(sync): harden local-first user data outbox

# Worklog - Immediate user-data sync hardening

## Thoi gian

- Ngay: 2026-06-30
- Bat dau: not recorded
- Ket thuc: 2026-06-30 10:35 +07:00
- Timezone: Asia/Saigon

## Pham vi

- Loai task: coding
- Module chinh: M01 `ONBOARDING_PROFILE`, M05 `AUTH_PROFILE_SYNC`, local SQLite sync outbox
- Yeu cau goc: implement local-first full snapshot sync for authenticated user data changes, queue Supabase writes through outbox, and avoid direct UI writes to Supabase.

## Da lam

- Bumped local DB version to v11 and added migration to backfill missing or empty sync ids for user-owned tables before recreating sync triggers.
- Kept public Supabase contract unchanged: `sync_my_mobile_snapshot(p_snapshot jsonb)`.
- Refactored V1 onboarding repository to read the current Supabase user id through the auth current-user helper instead of profile mutation service.
- Reduced `AuthProfileService` to a read-only auth-profile helper so onboarding/profile writes stay local-first and pass through SQLite outbox.
- Confirmed existing post-commit write paths request non-blocking sync drain for daily health tracking, meal/lifestyle completion, notification actions, and profile/settings updates.
- Updated contract and datasource tests for dispatcher-based sync, authenticated onboarding completion, profile offline retry, cloud table allowlists, and migration v11 id backfill.

## File code/docs da sua

- `lib/core/storage/localdb/database_version.dart` - bump DB version to 11.
- `lib/core/storage/localdb/migrations/migration_manager.dart` - add v11 id backfill and sync schema recreation.
- `lib/app_versions/v1/features/onboarding/domain/repositories/onboarding_repository_impl.dart` - use current auth user reader for authenticated local writes.
- `lib/app_versions/v1/features/onboarding/providers/repository_providers.dart` - remove profile mutation service dependency.
- `lib/services/supabase/auth/auth_profile_service.dart` - keep read-only current-user helper.
- `test/**` targeted sync/onboarding/profile/migration contract tests - update and add coverage.
- `docs/checklist/**` - update coding evidence and next implementation backlog.

## Tai lieu lien quan

- `docs/checklist/checklist_complete_DD.md`
- `docs/checklist/checklist_task_coding.md`
- `docs/worklog/2026-06-30/001-worklog-immediate-user-data-sync.md`
- `.codex/workflows/coding.md`

## Commands

- `dart format <touched code/test files>` - PASS.
- `flutter analyze <touched Dart files>` - PASS.
- `flutter test test/services/supabase/cloud_sync/user_data_sync_outbox_test.dart test/app_versions/v2/features/cloud_sync/cloud_sync_contract_test.dart test/app_versions/v2/features/cloud_sync/authenticated_user_data_sync_repository_test.dart test/app_versions/v1/features/onboarding/onboarding_local_datasource_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart test/features/settings/profile_update_contract_test.dart test/features/daily_health_tracking/data/daily_health_tracking_local_datasource_write_test.dart test/core/storage/localdb/migration_manager_test.dart` - PASS.
- `flutter test test/features/meal_plan/data/meal_plan_completion_test.dart test/features/lifestyle_schedule/data/lifestyle_schedule_completion_test.dart test/services/notifications/notification_action_handler_test.dart test/core/storage/localdb/sync/local_user_data_sync_dispatcher_test.dart` - PASS.
- `flutter test <combined targeted sync/onboarding/profile/daily/meal/lifestyle/notification/migration suite>` - PASS, 47 tests.
- `flutter test test/services/supabase/cloud_sync/user_data_sync_outbox_test.dart` - PASS after cleanup of one unnecessary import.
- `.codex/tool/codex_quick_check.ps1` - FAIL at global `dart format --set-exit-if-changed .`; it formatted 7 pre-existing V1 legacy files outside this scope, and those files were restored.
- `git diff --check` - PASS with Git LF/CRLF warnings only.

## Loi/Rui ro

- Da fix: Direct onboarding/profile Supabase mutation path removed from runtime code; tests now validate dispatcher/local-first sync contract.
- Da fix: Local sync triggers get stable ids after v11 backfill, including tables with null or empty ids.
- Chua fix: Supabase sandbox/RLS/cross-device acceptance evidence is still pending.
- Chua fix: FamilyPlus subject-aware sync/evidence remains backlog.
- Can kiem tra tiep: Run sandbox smoke for authenticated onboarding/profile sync, retry behavior, and distinct-user isolation.

## Ty le hoan thanh

- Hoan thanh: coding slice for local-first authenticated user-data outbox hardening.
- Dang do: production acceptance evidence in Supabase sandbox/RLS/cross-device flows.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: good for local runtime and contract-test scope; no Supabase schema change was introduced.
- Muc do hoan thanh task: complete for requested code path hardening, pending only external acceptance evidence.
- Bang chung kiem chung: 47 targeted tests passed, supplementary write-path tests passed, and `git diff --check` passed.
- Diem ton token/chua toi uu: quick check global format touched unrelated legacy files; restored them and recorded the blocker.
- Cach toi uu cho phien sau: run targeted format/tests first and reserve global quick check for branches with known repository-wide formatting clean.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
