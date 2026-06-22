Commit de xuat: docs(worklog): ghi nhan phien fix health scoring flow

# Worklog - Fix health scoring zero flow

## Thoi gian

- Ngay: 2026-06-22
- Bat dau: 16:10
- Ket thuc: 16:14
- Timezone: Asia/Saigon (+07:00)

## Pham vi

- Loai task: bugfix
- Module chinh: v1 dashboard daily score, v2 health_scoring placeholder, docs/worklog.
- Yeu cau goc: Implement plan fix remaining health scoring flow tu worklog 006/007.
- Gioi han: Khong implement final v2 health-score formula, quota, membership entitlement, FamilyPlus, Sale/referral, hoac Supabase contract vi DD Q-03/Q-04/Q-05/Q-06 va NB-RISK-001 van open.

## Da lam

- Them `DashboardDailyMetrics.hasDailyScoreInputs` de phan biet missing score input voi score bang 0.
- Doi dashboard score panel: chi hien `--` khi chua co input; neu co input that va score = 0 thi hien `0` va copy Nami nhe nhang.
- Doi daily summary de zero score co input that khong bi xem nhu missing-data state.
- Cap nhat `V2HealthScoringFeature` de ghi ro v1 local daily care score khac v2 official health scoring formula.
- Them regression tests cho no-input score va zero-progress score.
- Cap nhat worklog 006: tick muc "Lam ro dashboard score hien tai khac v2 health_scoring BD".
- Tao fixbug note `docs/fixbug/health-score-zero-inputs/001-fixbug-health-score-zero-inputs.md`.

## File code/docs da sua

- `lib/app_versions/v1/features/dashboard/domain/entities/dashboard_dynamic_entity.dart` - sua - them getter `hasDailyScoreInputs`.
- `lib/app_versions/v1/features/dashboard/domain/services/dashboard_companion_service.dart` - sua - copy zero-score voi input that.
- `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart` - sua - score panel tach `--` voi `0`.
- `lib/app_versions/v2/features/health_scoring/health_scoring.dart` - sua - ghi ro v2 official health scoring van blocked boi Q-05.
- `test/features/dashboard/data/dashboard_dynamic_local_datasource_test.dart` - sua - them regression no-input va zero-progress input.
- `test/features/dashboard/domain/dashboard_companion_service_test.dart` - sua - them regression domain copy.
- `docs/worklog/2026-06-22/006-worklog-module-flow-audit.md` - sua - cap nhat status health scoring/dashboard score.
- `docs/fixbug/health-score-zero-inputs/001-fixbug-health-score-zero-inputs.md` - tao - ghi root cause/fix/evidence.
- `docs/worklog/2026-06-22/008-worklog-fix-health-scoring-flow.md` - tao - worklog phien nay.

## Tai lieu lien quan

- `docs/worklog/2026-06-22/006-worklog-module-flow-audit.md`
- `docs/worklog/2026-06-22/007-worklog-fix-module-flow.md`
- `docs/DD/product_flow/07_FEATURE_HEALTH_SCORE_SCHEDULE_COMPLETION.md`
- `docs/DD/product_flow/15_TEST_ACCEPTANCE_AND_TRACEABILITY.md`
- `.codex/AGENTS.md`
- `.codex/DOCS_WORKFLOW.md`

## Commands

- `dart format lib/app_versions/v1/features/dashboard/domain/entities/dashboard_dynamic_entity.dart lib/app_versions/v1/features/dashboard/domain/services/dashboard_companion_service.dart lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart lib/app_versions/v2/features/health_scoring/health_scoring.dart test/features/dashboard/data/dashboard_dynamic_local_datasource_test.dart test/features/dashboard/domain/dashboard_companion_service_test.dart`: PASS.
- `flutter test test/features/dashboard/data/dashboard_dynamic_local_datasource_test.dart test/features/dashboard/domain/dashboard_companion_service_test.dart`: PASS.
- `flutter analyze`: PASS.
- `flutter test`: PASS - 309 tests pass.
- `git diff --check`: PASS - chi co warning line-ending LF se thanh CRLF khi Git touch file, khong co whitespace error.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - refresh history/task-skills sau worklog moi.

## Loi/Rui ro

- Da fix: v1 dashboard khong con tron missing score input voi real zero-progress score.
- Chua fix: v2 official health scoring formula/weights/skip-miss policy vi Q-05 van open.
- Can kiem tra tiep:
  - NB-RISK-001: Supabase sandbox/staging verification pending.
  - NB-RISK-002: Product flow DD open decisions Q-01..Q-10.
  - Free quota va membership entitlement chi implement khi backend/DD Ready.

## Ty le hoan thanh

- Hoan thanh: Code/test/docs cho dashboard zero-score flow va v2 health_scoring placeholder clarification.
- Dang do: Quota Free, membership entitlement/effective access, v2 official formula, FamilyPlus, Sale/referral theo DD/Supabase blockers.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - fix dung bug nho, co regression tests va khong mo rong sang Supabase/entitlement khi DD chua Ready.
- Muc do hoan thanh task: Hoan thanh plan health scoring flow.
- Bang chung kiem chung: Targeted tests, analyze, full test, `git diff --check`, va history refresh pass.
- Diem ton token/chua toi uu: Da tranh doc lai raw source rong; ton token chu yeu do can giu context worklog 006/007.
- Cach toi uu cho phien sau: Neu tiep tuc P1, bat dau tu DD quota/entitlement va Supabase contract; khong sua UI truoc khi backend decision Ready.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md` neu implement quota/entitlement moi; `.codex/task-skills/bugfix.md` neu tiep tuc fix runtime nho.
