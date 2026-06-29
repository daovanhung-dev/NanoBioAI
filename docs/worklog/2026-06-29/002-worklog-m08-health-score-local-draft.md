Commit de xuat: feat(health-scoring): implement M08 local draft

# Worklog - M08 Health Score Local Draft

## Thoi gian

- Ngay: 2026-06-29
- Timezone: Asia/Saigon (+07:00)

## Pham vi

- Loai task: coding + tests + checklist.
- Module chinh: M08 `HEALTH_SCORE_HABITS`.
- Yeu cau goc: implement plan "Hoan Thanh M08 Local Draft".

## Da lam

- Them M08 v2 feature structure trong `lib/app_versions/v2/features/health_scoring/`.
- Them `HealthScoreHabitsFn01` va `HealthScoreHabitsFn02`.
- Them calculator local draft version `m08_local_draft_2026_06`.
- Them SQLite read model doc du lieu tu `lifestyle_schedule_items`, `meal_plans`, `daily_health_tasks`, va `health_tracking_logs`.
- Dung `lifestyle_schedule_items` lam canonical khi co link meal/task de tranh double count.
- Them Riverpod providers, view model states, va page `/v2/health-score`.
- Cap nhat v2 router/path, v2 home entry, va guest route guard test.
- Cap nhat checklist M08: coding progress local draft, official blocker van la Q-14/Q-15.

## File code/docs da sua

- `lib/app_versions/v2/features/health_scoring/` - tao/sua - domain/application/data/provider/presentation.
- `lib/app_versions/v2/router/` - sua - them route `/v2/health-score`.
- `lib/app_versions/v2/features/home/presentation/pages/v2_home_page.dart` - sua - them entry point.
- `test/app_versions/v2/features/health_scoring/` - tao - domain/data/provider/widget tests.
- `test/app_versions/v1/router/v1_route_guards_test.dart` - sua - route moi van bi chan voi guest.
- `docs/checklist/` - sua - cap nhat tien do M08 va blocker Q-14/Q-15.

## Commands

- `dart format ...`: PASS.
- `flutter analyze lib\app_versions\v2\features\health_scoring lib\app_versions\v2\router lib\app_versions\v2\features\home\presentation\pages\v2_home_page.dart test\app_versions\v2\features\health_scoring test\app_versions\v1\router\v1_route_guards_test.dart`: PASS.
- `flutter test test\app_versions\v2\features\health_scoring`: PASS.
- `flutter test test\architecture_version_boundary_test.dart test\app_versions\v1\router\v1_route_guards_test.dart`: PASS.
- `flutter test test\features\dashboard\data\dashboard_dynamic_local_datasource_test.dart test\features\dashboard\domain\dashboard_companion_service_test.dart test\features\lifestyle_schedule\data\lifestyle_schedule_completion_test.dart`: PASS.

## Loi/Rui ro

- Chua claim official health score; DD M08 van Draft.
- Q-14 official formula/weights/skip-miss policy chua chot.
- Q-15 FamilyPlus subject/consent chua chot, nen local draft chi support current actor subject.
- Chua them Supabase schema/RLS/ledger persistence/backend contract.

## Ty le hoan thanh

- Hoan thanh: local draft vertical slice co tests.
- Dang do: official formula, production ledger/backend, FamilyPlus subject boundary.
