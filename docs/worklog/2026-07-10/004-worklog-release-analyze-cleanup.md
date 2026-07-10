Commit de xuat: docs(worklog): ghi nhan phien cleanup release analyze

# Worklog - Release analyze cleanup

## Thoi gian

- Ngay: 2026-07-10
- Bat dau: 14:35
- Ket thuc: 14:37
- Timezone: Asia/Saigon

## Pham vi

- Loai task: bugfix
- Module chinh: Nabi providers/UI, onboarding UI, shared Nabi widgets, release
  analyzer gate
- Yeu cau goc: Tim va fix no ky thuat/bug an trong toan du an; xu ly debt P1
  `flutter analyze` fail.

## Da lam

- Chay lai `flutter analyze` va xac dinh cac issue con lai thuoc Nabi naming,
  onboarding UI unused/deprecated code, import/prefix lint va shared Nabi
  deprecated color API.
- Doi provider/getter Nabi sang lowerCamelCase va update call sites.
- Chuan hoa import Nabi visual state ve `nabi_visual_state.dart`.
- Don onboarding UI analyzer warnings: unused helper/widgets/imports, deprecated
  dropdown value API va child argument order.
- Doi shared Nabi `withOpacity` sang `withValues(alpha: ...)`.
- Sua layout compact cua `OnboardingEntryPage` de CTA chinh tappable o viewport
  800x600; test entry page khong con hit-test miss.
- Cap nhat issue/todo/checklist/fixbug docs cho analyzer gate.

## File code/docs da sua

- `lib/app_versions/v1/features/nabi/providers/nabi_provider.dart`
- `lib/app_versions/v1/features/nabi/presentation/nabi_page_mixin.dart`
- `lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart`
- `lib/app_versions/v1/features/nabi/presentation/widgets/nabi_floating_overlay.dart`
- `lib/app_versions/v1/features/nabi/presentation/widgets/nabi_character_widget.dart`
- `lib/app_versions/v1/features/nabi/presentation/nabi_route_observer.dart`
- `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart`
- `lib/app_versions/v1/features/ai_chat/presentation/controllers/ai_chat_controller.dart`
- `lib/features/nabi/application/nabi_controller.dart`
- `lib/features/nabi/presentation/widgets/nabi_assistant_overlay.dart`
- `lib/features/nabi/presentation/widgets/nabi_character.dart`
- `lib/features/nabi/presentation/navigation/nabi_route_observer.dart`
- `test/features/nabi/application/nabi_controller_test.dart`
- `lib/app_versions/v1/features/onboarding/presentation/widgets/basic_info_step.dart`
- `lib/app_versions/v1/features/onboarding/presentation/widgets/onboarding_step_shell.dart`
- `lib/app_versions/v1/features/onboarding/presentation/widgets/review_step.dart`
- `lib/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart`
- `lib/app_versions/v1/features/splash/presentation/pages/splash_page.dart`
- `docs/checklist/checklist_technical_debt.md`
- `docs/issues/release-analyze-red-290-issues/001-issue-release-analyze-red-290-issues.md`
- `docs/todo/release-analyze-red-290-issues/001-todo-release-analyze-red-290-issues.md`
- `docs/fixbug/release-analyze-red-290-issues/001-fixbug-release-analyze-red-290-issues.md`

## Commands

- `dart format ...`: PASS - affected Dart files formatted.
- `dart analyze ...`: PASS - affected Nabi/onboarding/splash files no issues.
- `flutter analyze`: PASS - no issues found.
- `flutter test test/features/nabi/application/nabi_controller_test.dart`: PASS.
- `flutter test test/app_versions/v1/features/onboarding/onboarding_entry_page_test.dart test/app_versions/v1/features/onboarding/onboarding_local_datasource_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart`: PASS.
- `flutter test test/core/config/app_env_test.dart test/services/ai/ai_service_test.dart`: PASS.

## Loi/Rui ro

- Da fix: Analyzer gate khong con do tren current branch.
- Da fix: Nabi import/case mismatch khong con duoc analyzer bao loi.
- Da fix: Onboarding entry primary CTA khong con bi tap miss trong viewport
  compact landscape cua widget test.
- Chua fix: Full `flutter test` suite van la debt rieng trong checklist.
- Chua fix: Format hygiene toan repo van can kiem chung/xu ly bang todo rieng.

## Ty le hoan thanh

- Hoan thanh: Debt P1 release analyzer fail va debt Nabi import case mismatch.
- Dang do: Objective toan du an van con cac debt P1/P2 khac trong checklist.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - analyzer gate duoc fix bang patch nho theo nhom va
  co targeted regression tests.
- Muc do hoan thanh task: hoan thanh them mot cum release debt trong objective
  lon.
- Bang chung kiem chung: full `flutter analyze` PASS, targeted tests PASS.
- Diem ton token/chua toi uu: Output PowerShell hien thi mojibake voi mot so file
  UTF-8; lan sau dung `rg` khi can doc chuoi tieng Viet chinh xac.
- Cach toi uu cho phien sau: Tiep tuc theo checklist, uu tien full test suite
  fail hoac format hygiene tuy theo blast radius.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
