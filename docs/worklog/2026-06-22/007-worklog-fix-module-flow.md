Commit de xuat: docs(worklog): ghi nhan phien fix module flow

# Worklog - Fix module flow P0

## Thoi gian

- Ngay: 2026-06-22
- Bat dau: 12:20
- Ket thuc: 12:45
- Timezone: Asia/Saigon (+07:00)

## Pham vi

- Loai task: bugfix
- Module chinh: v1 onboarding, generated plan service, v1/v2 router gate, v2 cloud sync test, docs/worklog.
- Yeu cau goc: Implement plan sua cac module sai luong trong `docs/worklog/2026-06-22/006-worklog-module-flow-audit.md`, cap nhat lai tinh trang module tai worklog 006.
- Gioi han: Chi fix P0 runtime va centralized Guest/V1 route gate. Khong implement production quota, entitlement, FamilyPlus, Sale/referral vi DD/Supabase van blocked.

## Da lam

- Them `GeneratedPlanService.generateInitialGuestPlan()` de guest tao lich ca nhan dau tien khong can Supabase session.
- Giu `GeneratedPlanService.generateNextPlan()` authenticated-only cho generation tiep theo.
- Doi onboarding completion callback sang `OnboardingCompletionResult`.
- `onboarding_controller.dart` chi set completed khi callback tao initial plan thanh cong; skip/fail thi khong dua guest vao app.
- Them centralized guest allowlist guard va gan vao `v1Router`, `v2Router`.
- Mo rong test cho guest initial plan, onboarding completed flag, route allowlist, va cloud sync route-ready.
- Cap nhat `006-worklog-module-flow-audit.md` bang bang trang thai sau fix va tick checklist da xu ly.
- Tao fixbug note `docs/fixbug/guest-initial-plan-flow/001-fixbug-guest-initial-plan-flow.md`.

## File code/docs da sua

- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - sua - tach initial guest plan khoi additional authenticated generation.
- `lib/main.dart` - sua - onboarding callback goi initial guest plan, khong return som khi guest.
- `lib/main_v2.dart` - sua - dong bo onboarding callback voi `main.dart`.
- `lib/app_versions/v1/features/onboarding/providers/onboarding_completion_provider.dart` - sua - them typed completion result va exception copy.
- `lib/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart` - sua - completed flag phu thuoc initial plan success.
- `lib/app_versions/v1/router/v1_route_guards.dart` - sua - centralized guest allowlist gate.
- `lib/app_versions/v1/router/v1_router.dart` - sua - gan global guest allowlist redirect.
- `lib/app_versions/v2/router/v2_router.dart` - sua - gan global guest allowlist redirect cho app v2 compose v1 routes.
- `test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart` - sua - regression test guest initial plan va additional auth gate.
- `test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart` - tao - regression test completed flag.
- `test/app_versions/v1/router/v1_route_guards_test.dart` - tao - regression test guest route allowlist.
- `test/app_versions/v2/features/cloud_sync/authenticated_user_data_sync_repository_test.dart` - sua - verify sync route-ready sau pending guest push.
- `docs/worklog/2026-06-22/006-worklog-module-flow-audit.md` - sua - cap nhat trang thai module sau fix.
- `docs/fixbug/guest-initial-plan-flow/001-fixbug-guest-initial-plan-flow.md` - tao - ghi root cause/fix/evidence.
- `docs/worklog/2026-06-22/007-worklog-fix-module-flow.md` - tao - worklog phien implementation.

## Tai lieu lien quan

- `docs/worklog/2026-06-22/006-worklog-module-flow-audit.md`
- `docs/BD/project_flow/BD_Product_Flow_Membership_Sale.md`
- `docs/DD/product_flow/04_FEATURE_GUEST_ONBOARDING_INITIAL_SCHEDULE.md`
- `docs/DD/product_flow/05_FEATURE_AUTH_MEMBERSHIP_ACCESS_GATE.md`
- `docs/DD/product_flow/06_FEATURE_FREE_QUOTA_AI_CHAT_AND_SCHEDULE.md`
- `.codex/AGENTS.md`
- `.codex/DOCS_WORKFLOW.md`

## Commands

- `dart format ...`: PASS - format cac Dart file da sua.
- `flutter test test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart test/app_versions/v1/router/v1_route_guards_test.dart test/app_versions/v2/features/cloud_sync/authenticated_user_data_sync_repository_test.dart test/app_versions/v2/features/auth/auth_route_state_resolver_test.dart`: PASS.
- `flutter test`: PASS - 306 tests pass.
- `powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1`: PASS - `flutter pub get`, format check, analyze, va full test pass.
- `git diff --check`: PASS - chi co warning line-ending LF se thanh CRLF khi Git touch file, khong co whitespace error.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - refresh history/task-skills sau worklog moi.

## Loi/Rui ro

- Da fix: P0 guest onboarding initial plan, generated plan auth policy split, onboarding completed flag, auth sync route-ready regression, centralized guest route allowlist.
- Chua fix: P1 quota Free, membership entitlement/effective access, v2 health scoring, v3 FamilyPlus, Sale/referral production flow.
- Can kiem tra tiep:
  - NB-RISK-001: Supabase sandbox/staging verification pending.
  - NB-RISK-002: Product flow DD open decisions Q-01..Q-10.
  - Manual QA guest onboarding -> initial AI plan -> reminders -> dashboard voi AI key hop le.

## Ty le hoan thanh

- Hoan thanh: Code/test/docs cho P0 runtime va route allowlist.
- Dang do: P1/P2 blocked/planned theo DD va Supabase verification.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - sua dung pham vi da chot, co regression tests va cap nhat worklog 006.
- Muc do hoan thanh task: Hoan thanh phan implementation theo plan, validation cuoi pass.
- Bang chung kiem chung: Targeted tests, full `flutter test`, quick check, `git diff --check`, va history refresh pass.
- Diem ton token/chua toi uu: Can doc them mot so file test/entity de tao fake data dung shape; khong doc raw `lib` rong.
- Cach toi uu cho phien sau: Neu tiep tuc P1, bat dau tu DD quota/entitlement va Supabase contract thay vi mo rong P0.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md` cho bugfix tiep; `.codex/task-skills/coding.md` neu implement P1 quota/entitlement.
