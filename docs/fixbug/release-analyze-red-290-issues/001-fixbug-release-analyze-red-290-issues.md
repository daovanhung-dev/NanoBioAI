Commit de xuat: fix(release): dua flutter analyze ve trang thai sach

# Fixbug - Release analyze red issues

## Tom tat

- `flutter analyze` dang la release gate do, voi cac loi lint/analyzer con lai
  quanh Nabi providers/imports, onboarding UI, deprecated Flutter APIs va unused
  code.
- Khi chay lai sau batch fix, `flutter analyze` pass voi `No issues found`.

## Cach sua

- Doi cac Riverpod provider/getter Nabi sang lowerCamelCase:
  `nabiContextProvider`, `nabiVisualStateProvider`, `nabiControllerProvider`,
  `ref.nabi`.
- Cap nhat call sites V1 Nabi, dashboard, AI chat va shared Nabi controller theo
  ten provider/getter moi.
- Chuan hoa import Nabi visual state ve `nabi_visual_state.dart`.
- Don onboarding UI warnings:
  - Bo unused `_ProfileProgressBanner`, `_ProgressRing`,
    `_countCompletedFields`, `_getShortName`, `completedFields`.
  - Doi prefix import onboarding options sang lower_case.
  - Doi `DropdownButtonFormField.value` sang `initialValue`.
  - Dua `child` argument ve cuoi constructor call.
  - Bo unused import/unused `dart:ui`.
- Doi deprecated `withOpacity` sang `withValues(alpha: ...)` trong shared Nabi
  overlay/character widgets.
- Nen layout compact cua `OnboardingEntryPage` tren short landscape viewport:
  hero thap hon, gap nho hon, compact cards bo benefit chips de CTA chinh van
  tappable trong viewport 800x600.

## Kiem chung

- `flutter analyze`: PASS - no issues found.
- `dart analyze` tren cac file Nabi/onboarding/splash bi sua: PASS.
- `flutter test test/features/nabi/application/nabi_controller_test.dart`: PASS.
- `flutter test test/app_versions/v1/features/onboarding/onboarding_entry_page_test.dart`: PASS.
- `flutter test test/app_versions/v1/features/onboarding/onboarding_entry_page_test.dart test/app_versions/v1/features/onboarding/onboarding_local_datasource_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart`: PASS sau khi sua layout compact.

## Luu y

- Fix nay chi chot gate `flutter analyze`; full `flutter test` van la debt rieng
  trong checklist release-test-suite-fails.
- Format hygiene toan repo van can xu ly bang todo rieng neu
  `dart format --set-exit-if-changed lib test` con fail.
