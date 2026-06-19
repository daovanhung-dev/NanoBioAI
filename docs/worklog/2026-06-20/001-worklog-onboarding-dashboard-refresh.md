Commit de xuat: docs(worklog): ghi nhan phien onboarding dashboard refresh

# Worklog - Onboarding Dashboard Refresh

## Thoi gian

- Ngay: 2026-06-20
- Bat dau: khong ghi nhan chinh xac
- Ket thuc: khong ghi nhan chinh xac
- Timezone: Asia/Saigon

## Pham vi

- Loai task: coding
- Module chinh: onboarding, dashboard
- Yeu cau goc: cap nhat onboarding 8 buoc voi consent rieng, thu gon cac lua chon, cap nhat gioi tinh/nghe nghiep, lam noi bat CTA tao du lieu 7 ngay tren dashboard va nhac khi den ngay cuoi lich trinh.

## Da lam

- Doi onboarding thanh 8 buoc va them view `ConsentStep`.
- Tach xac nhan trach nhiem/mien tru khoi Extras, giu validation `agreed` o buoc save.
- Gioi tinh chi con Nam/Nu; bo nghe IT va them noi tro/nghi huu.
- Thu gon chip, card, picker va nut dieu huong onboarding.
- Them banner dashboard khi `remainingDays == 1` va lam CTA tao du lieu 7 ngay noi bat hon.
- Cap nhat widget/data tests cho flow 8 buoc va plan status ngay cuoi/het han.

## File code/docs da sua

- `lib/core/constants/onboarding_constants.dart` - sua - cap nhat catalog gioi tinh va tong buoc.
- `lib/features/onboarding/presentation/pages/onboarding_page.dart` - sua - them route buoc consent.
- `lib/features/onboarding/presentation/controllers/onboarding_controller.dart` - sua - cap nhat gioi han buoc/log summary.
- `lib/features/onboarding/presentation/widgets/consent_step.dart` - tao - view xac nhan trach nhiem va mien tru.
- `lib/features/onboarding/presentation/widgets/*` - sua - compact choice controls va bo agreement khoi Extras.
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` - sua - CTA/bannner tao du lieu 7 ngay.
- `lib/features/dashboard/presentation/widgets/companion/dashboard_companion_widgets.dart` - sua - copy plan status ngay cuoi.
- `test/widget_test.dart` - sua - test flow onboarding 8 buoc.
- `test/features/dashboard/data/dashboard_dynamic_local_datasource_test.dart` - sua - test plan status ngay cuoi/het han.
- `test/architecture_preservation_property_test.dart` - sua - cap nhat invariant 8 buoc va parser/normalizer AI hien tai.
- `docs/features/onboarding-dashboard-refresh/001-feature-onboarding-dashboard-refresh.md` - tao - tom tat feature.

## Tai lieu lien quan

- [Onboarding va Dashboard Refresh](../../features/onboarding-dashboard-refresh/001-feature-onboarding-dashboard-refresh.md)

## Commands

- `dart format ...`: PASS - format cac file trong scope.
- `flutter test test/widget_test.dart`: PASS.
- `flutter test test/features/dashboard/data/dashboard_dynamic_local_datasource_test.dart`: PASS.
- `flutter test test/architecture_preservation_property_test.dart`: PASS.
- `powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1`: PASS/WARN - script exit 0 va in `QUICK CHECK PASSED`; output co `flutter analyze` 292 issues co san va full `flutter test` co 1 fail ngoai scope o `test/features/features_hub/features_hub_page_test.dart` do khong tim thay text `AI Coach`.

## Loi/Rui ro

- Da fix: snackbar trong widget test che nut consent; test da clear snackbar truoc khi tiep tuc.
- Chua fix: analyzer warnings/info co san trong repo; full test fail ngoai scope o `features_hub_page_test.dart`.
- Can kiem tra tiep: UI thuc te tren mobile de dam bao cac choice card gon hon nhung van de cham.
