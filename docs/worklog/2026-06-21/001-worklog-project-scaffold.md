Commit de xuat: docs(worklog): ghi nhan phien project scaffold

# Worklog - Scaffold cau truc du an

## Thoi gian

- Ngay: 2026-06-21
- Bat dau: 12:38
- Ket thuc: 12:49
- Timezone: Asia/Saigon (+07:00)

## Pham vi

- Loai task: coding/refactor
- Module chinh: project structure, access version boundary, sale/referral scaffold
- Yeu cau goc: refactor toan bo du an de phu hop du an; cac chuc nang chua lam phai co folder rieng va file tuong trung.

## Da lam

- Doc context `.codex`, BD product flow, DD authentication, access playbook, router/app shell, va boundary tests.
- Them planned scaffold cho v2 Free/auth modules con thieu.
- Tao `lib/app_versions/v3/` voi app/router/home shell va planned feature placeholders.
- Tao `lib/sale_referral/` doc lap cho referral code, Sale dashboard, commission, payment events.
- Cap nhat `.codex` map va boundary test de ghi nhan cau truc moi.
- Tach v1 router khoi import truc tiep v2 auth bang `V1AuthEntryPage`.
- Cap nhat feature hub widget test theo UI hien tai.

## File code/docs da sua

- `.codex/AGENTS.md` - sua - bo sung source root v3 va sale/referral.
- `.codex/PROJECT_MAP.md` - sua - bo sung route doc cho v2 planned modules, v3, sale_referral.
- `lib/app_versions/v2/features/README.md` - sua - them status cac feature v2 planned.
- `lib/app_versions/v2/features/*` - tao - placeholder cho access/quota/score.
- `lib/app_versions/v3/` - tao - scaffold Plus/FamilyPlus planned.
- `lib/sale_referral/` - tao - scaffold Sale/referral doc lap.
- `lib/app_versions/v1/features/auth/presentation/pages/v1_auth_entry_page.dart` - tao - auth entry khong import v2.
- `lib/app_versions/v1/router/v1_router.dart` - sua - dung v1 auth entry thay vi import v2 auth page.
- `test/architecture_version_boundary_test.dart` - sua - mo rong boundary test cho v3 va sale_referral.
- `test/features/features_hub/features_hub_page_test.dart` - sua - cap nhat test theo UI feature hub hien tai.
- `docs/features/project-scaffold/001-feature-project-scaffold.md` - tao - ghi mo ta scaffold.
- `docs/worklog/2026-06-21/001-worklog-project-scaffold.md` - tao - ghi nhan phien lam viec.

## Tai lieu lien quan

- [Scaffold cau truc du an](../../features/project-scaffold/001-feature-project-scaffold.md)

## Commands

- `dart format lib test`: PASS
- `flutter analyze <scaffold va boundary files>`: PASS
- `flutter test test\architecture_version_boundary_test.dart`: PASS
- `flutter test test\features\features_hub\features_hub_page_test.dart`: PASS
- `flutter test`: PASS - 282 tests passed.
- `flutter analyze`: FAIL - 288 warning/info hien huu ngoai pham vi scaffold.

## Loi/Rui ro

- Da fix: v1 router khong con import v2 auth; feature hub test khop UI hien tai; full test suite PASS.
- Chua fix: chua implement logic that cho membership/quota/v3/sale vi can DD chi tiet.
- Can kiem tra tiep: xu ly no ky thuat full analyze trong phien rieng.
