Commit de xuat: feat(onboarding,dashboard): cap nhat xac nhan va nhac tao du lieu

# Onboarding va Dashboard Refresh

## Muc tieu

- Tach buoc xac nhan trach nhiem va mien tru trach nhiem thanh mot view rieng trong onboarding.
- Lam cac lua chon onboarding gon hon de tiet kiem khong gian.
- Nhac user tao du lieu 7 ngay moi khi hom nay la ngay cuoi cua lich trinh.

## Pham vi

- Bao gom: onboarding 8 buoc, gioi tinh 2 lua chon, nghe nghiep bo IT va them noi tro/nghi huu, CTA dashboard cho du lieu 7 ngay.
- Khong bao gom: doi schema SQLite, migration, goi API moi, hoac refactor data layer.

## Luong hoat dong

1. User di qua onboarding den buoc Extras.
2. User sang buoc Consent de doc trach nhiem va mien tru.
3. User bat xac nhan dong y roi moi sang Review.
4. Dashboard doc `DashboardPlanStatus` tu data layer.
5. Neu `remainingDays == 1`, dashboard hien banner yeu cau tao du lieu 7 ngay moi.

## Du lieu va luu tru

- Nguon doc: state onboarding hien co va dashboard dynamic provider.
- Noi ghi: tiep tuc dung `state.agreed` va luu onboarding hien co.
- Migration/version: khong thay doi.

## UI/UX

- Loading: CTA tao du lieu 7 ngay hien trang thai dang tao.
- Empty: plan status hien copy chuan khi chua co ke hoach.
- Error: giu snackbar loi tao plan hien co.
- Success: snackbar dashboard bao Nami da them ke hoach 7 ngay.

## Files

- `lib/features/onboarding/presentation/widgets/consent_step.dart` - them view xac nhan rieng.
- `lib/features/onboarding/presentation/widgets/*` - thu gon chip/card/picker lua chon.
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` - them banner ngay cuoi va CTA noi bat.
- `lib/features/dashboard/presentation/widgets/companion/dashboard_companion_widgets.dart` - cap nhat copy plan status.

## Kiem chung

- Command: `flutter test test/widget_test.dart`
- Ket qua: PASS
- Command: `flutter test test/features/dashboard/data/dashboard_dynamic_local_datasource_test.dart`
- Ket qua: PASS
- Command: `flutter test test/architecture_preservation_property_test.dart`
- Ket qua: PASS

## Lien ket

- Worklog: [Worklog - onboarding dashboard refresh](../../worklog/2026-06-20/001-worklog-onboarding-dashboard-refresh.md)

## Rui ro

- Quick check toan repo co output analyzer warnings va mot full-test fail ngoai scope o `test/features/features_hub/features_hub_page_test.dart`.
