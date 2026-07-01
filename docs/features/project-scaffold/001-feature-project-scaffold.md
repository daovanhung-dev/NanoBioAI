Commit de xuat: refactor(project): tao scaffold version va sale referral

# Scaffold cau truc du an

## Muc tieu

- Chuan hoa cau truc source theo BD product flow: v1 guest/basic, v2 authenticated Free, v3 Plus/FamilyPlus planned, va Sale/referral doc lap.
- Tao folder rieng va file placeholder cho cac feature chua trien khai de cac phien sau khong tao module sai vi tri.
- Giu nguyen runtime v1/v2 hien co, khong tu them paid/payment/referral logic khi chua co DD chi tiet.

## Pham vi

- Bao gom:
  - Scaffold v2 planned features cho membership entitlement, usage quota, personal schedule quota, va health scoring.
  - Scaffold v3 app/router/home va planned features cho Plus/FamilyPlus.
  - Scaffold `lib/sale_referral/` cho referral code, Sale dashboard, commission, va payment events.
  - Cap nhat boundary test va `.codex` map de nhan dien duong dan moi.
- Khong bao gom:
  - Khong wire v3 vao production entrypoint.
  - Khong tao payment, commission, family sharing, hoac paid access logic that.
  - Khong doi schema SQLite/Supabase.

## Luong hoat dong

1. Guest/basic tiep tuc chay qua `lib/app_versions/v1/`.
2. Authenticated Free tiep tuc chay qua `lib/app_versions/v2/`.
3. Plus/FamilyPlus co shell rieng trong `lib/app_versions/v3/` de chuan bi implement khi co BD/DD.
4. Sale/referral nam o `lib/sale_referral/`, doc lap voi version va membership tier.

## Du lieu va luu tru

- Nguon doc: BD product flow, DD authentication, `.codex` access playbook.
- Noi ghi: chua ghi runtime data moi.
- Table/model/entity: chua them schema moi.
- Migration/version: khong thay doi `DatabaseVersion.currentVersion`.

## UI/UX

- V3 home page la shell planned, dung copy tieng Viet va giong Nabi.
- Cac feature planned khong hien thi trong production flow hien tai.

## Files

- `lib/app_versions/v2/features/*` - them placeholder cho module Free/access/quota/score.
- `lib/app_versions/v3/` - them app/router/home va placeholder feature Plus/FamilyPlus.
- `lib/sale_referral/` - them placeholder cho axis Sale/referral doc lap.
- `.codex/PROJECT_MAP.md` va `.codex/AGENTS.md` - cap nhat duong dan moi.
- `test/architecture_version_boundary_test.dart` - mo rong boundary test cho v3 va sale_referral.

## Kiem chung

- Command: `dart format lib test`
- Ket qua: PASS
- Command: `flutter analyze lib\app_versions\v1\features\auth lib\app_versions\v1\router\v1_router.dart lib\app_versions\v2\features\membership_entitlement lib\app_versions\v2\features\usage_quota lib\app_versions\v2\features\health_scoring lib\app_versions\v2\features\personal_schedule_quota lib\app_versions\v3 lib\sale_referral test\architecture_version_boundary_test.dart`
- Ket qua: PASS
- Command: `flutter test test\architecture_version_boundary_test.dart`
- Ket qua: PASS
- Command: `flutter test`
- Ket qua: PASS - 282 tests passed.
- Command: `flutter analyze`
- Ket qua: FAIL - 288 warning/info hien huu ngoai pham vi scaffold, chu yeu `withOpacity` deprecated, unused helpers/imports, style lints trong v1/core/test.
- Case da test: format Dart, scaffold syntax, version boundary, feature hub UI test, va full Flutter test suite.

## Lien ket

- Worklog: [Worklog scaffold cau truc du an](../../worklog/2026-06-21/001-worklog-project-scaffold.md)

## Rui ro

- Cac placeholder moi chi la khung, chua thay the DD chi tiet cho membership, quota, v3 paid feature, FamilyPlus, payment, hoac Sale.
- Full `flutter analyze` con no ky thuat san co trong cac module cu; scoped analyze cho file scaffold va route vua sua da PASS.
