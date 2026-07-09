Commit de xuat: feat(schedule): dung lich trinh AI lam nhiem vu ngay

# Worklog - Daily schedule proof and score

## Thoi gian

- Ngay: 2026-07-09
- Bat dau: 12:10
- Ket thuc: 13:40
- Timezone: Asia/Saigon (+07:00)

## Pham vi

- Loai task: coding
- Module chinh: v1 lifestyle schedule, dashboard, localdb, cloud sync, Supabase docs
- Yeu cau goc: thay daily task Tam/Than/Tri/Nuoc bang lich trinh trong ngay tu AI, khoa moc sau 30 phut, bat buoc anh minh chung local, tinh diem ngay va wellness point sync Supabase.

## Da lam

- Doi route `/health-tracking` sang dung `LifestyleSchedulePage`, loai bo UI daily task grid/quick action legacy khoi man nay.
- Them `CompletionWindowStatus` va rule `start_time -> start_time + 30 phut`; complete/undo chi hop le trong cua so nay.
- Them flow camera proof qua `ScheduleProofImageService`, luu anh vao app documents `schedule_proofs/`, khong dua proof path len cloud.
- Them SQLite v13: cot proof local-only cho `lifestyle_schedule_items`, bang `health_score_ledgers`, bang `wellness_point_ledgers`.
- Them score formula `daily_schedule_equal_v1_2026_07`: `completed_due_items / due_items * 100`, hom nay chi tinh moc da den gio.
- Them wellness point ledger `+1` khi complete hop le va reversal `-1` khi undo trong cua so mo; balance tinh bang `SUM(points_delta)`.
- Dashboard metrics/progress/timeline uu tien schedule items va khong render standalone `daily_health_tasks` thanh nhiem vu thuong ngay.
- Notification background action `done` cho schedule item bi reject an toan vi thieu anh proof.
- Cap nhat cloud sync whitelist cho `health_score_ledgers` va `wellness_point_ledgers`; proof path chi nam trong local columns.
- Cap nhat `docs/supabase/*.sql` de co wellness point ledger, RLS subject-based, grant va mobile snapshot whitelist.
- Bo sung trigger/backfill outbox rieng cho `personal_schedule_ai_requests` vi bang nay dung `request_id` thay vi `id`, giu migration contract san co.
- Khoi phuc quota gateway fallback `row['allowed'] ?? row['committed']` va denied exception contract theo test Supabase hien co.

## File code/docs da sua

- `lib/app_versions/v1/features/lifestyle_schedule/**` - sua/tao - schedule status, proof image service, completion rule, score/point service, UI status pills.
- `lib/app_versions/v1/features/daily_health_tracking/presentation/pages/daily_health_tracking_page.dart` - sua - route cu render schedule page.
- `lib/app_versions/v1/features/dashboard/**` - sua - dashboard timeline/metrics/progress dung schedule; schedule complete can proof.
- `lib/app_versions/v1/services/notifications/notification_action_handler.dart` - sua - reject schedule done background action.
- `lib/core/storage/localdb/**` - sua/tao - DB v13, ledger tables/models/DAOs, migration, outbox triggers.
- `lib/app_versions/v2/features/cloud_sync/data/datasources/**` - sua - sync columns/tables, decode `breakdown` JSON.
- `docs/supabase/*.sql` - sua - Supabase ledger/schema/snapshot contract.
- `test/**` targeted - sua - regression tests cho schedule, dashboard, notification, migration, cloud sync, Supabase config.

## Tai lieu lien quan

- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `.codex/domains/lifestyle-schedule.md`
- `.codex/domains/dashboard.md`
- `.codex/domains/sqlite.md`
- `.codex/domains/notification.md`
- `.codex/domains/access-membership-referral.md`
- `.codex/DOCS_WORKFLOW.md`

## Commands

- `dart format` on touched Dart files: PASS.
- `flutter test test/features/lifestyle_schedule/data/lifestyle_schedule_completion_test.dart test/features/dashboard/data/dashboard_dynamic_local_datasource_test.dart test/services/notifications/notification_action_handler_test.dart test/core/storage/localdb/migration_manager_test.dart test/app_versions/v2/features/cloud_sync/cloud_sync_contract_test.dart test/docs/supabase_config_contract_test.dart`: PASS - 55 tests pass; Flutter van in canh bao asset directories thieu trong `pubspec.yaml`.
- `flutter analyze` targeted on touched source/test paths: PASS - no issues.
- `git diff --check`: PASS - chi co canh bao LF/CRLF san co tren Windows, khong co whitespace error.

## Loi/Rui ro

- Da fix: schedule item khong the complete truoc gio, khong the complete/undo sau 30 phut, va complete thieu proof path bi reject.
- Da fix: wellness point undo trong cung timestamp khong con bi drop do trung ledger id.
- Chua fix: app chua co UI voucher/redeem; dung scope earn/sync only theo yeu cau.
- Chua fix: proof image local path khong sync cloud; neu nguoi dung doi may se chi giu completion/score/point, khong co anh proof tren may moi.
- Can kiem tra tiep: manual camera permission/cancel flow tren thiet bi that va Supabase sandbox snapshot cho `health_score_ledgers`/`wellness_point_ledgers`.

## Ty le hoan thanh

- Hoan thanh: 100% trong pham vi coding da duyet.
- Dang do: khong lam voucher catalog/redeem UI theo dung scope.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - logic duoc gom vao entity/service/DAO, co migration va sync contract.
- Muc do hoan thanh task: da implement end-to-end local DB, UI, notification, sync docs va tests.
- Bang chung kiem chung: targeted test/analyze pass, diff check pass.
- Diem ton token/chua toi uu: patch cac file co mojibake can chia nho nhieu lan; lan sau doc snippet line-number truoc khi patch chuoi UI.
- Cach toi uu cho phien sau: voi schema sync, kiem tra migration duong cu goi trigger truoc khi table moi ton tai de tranh upgrade break.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
