Commit de xuat: feat(health): add M20-M29 catalog shell and BD

# Worklog - Advanced Health M20-M29 catalog shell

## Thoi gian

- Ngay: 2026-07-13
- Ket thuc: 14:02
- Timezone: Asia/Saigon

## Pham vi

- Loai task: coding
- Module chinh: M20-M29 Advanced Health
- Yeu cau goc: Tao BD chi tiet cho 10 chuc nang suc khoe M20-M29, them vao
  Danh muc chuc nang va dieu huong theo goi toi trang dang phat trien; chua
  trien khai nghiep vu, health data, AI, SQLite/Supabase hoac schema.

## Da lam

- Tao BD `BD-BIOAI-ADVANCED-HEALTH-001`, trang thai
  `Draft - UI catalog shell approved`, mo ta chi tiet M20-M29 va UC-25..UC-34.
- Ghi ro actor, input, main/exception flow, state, sensitive data, AI boundary,
  BR/AC, out-of-scope va dependency M04/M06/M07/M08/M09/M10/M11/M19.
- Khoa FamilyPlus full sharing: active joined members xem du lieu cua nhau sau
  disclosure; record tach actor/subject; remove/revoke/expiry dung quyen moi.
- Dong bo source registry voi bay nguon WHO/FDA/CDC/MedlinePlus bat buoc; AI
  chi co vai tro tuong lai o M24, M27 va M29.
- Them extension registry vao core Product Flow BD ma khong doi baseline
  M01-M19; cap nhat DD index, checklist va project map.
- Giu M20-M29 o DD 0% va business coding 0%; khong tao folder DD gia.
- Tao shared `HealthFeatureCatalogItem` cho dung 10 module, 3 Free/7 Plus,
  copy/icon/mau va dung ba preview item cho moi module.
- Chia Features Hub thanh hai khu vuc, giu nguyen chin cong cu cu va them muoi
  card `Theo doi chuyen sau dang phat trien`, tong cong 19 cong cu.
- Them mot route dong `/v2/health-modules/:moduleId` va
  `HealthModuleRoutePaths.detail(moduleId)`; khong tao 10 page/route rieng.
- Them pure access resolver va shared access page dung
  `effectiveAccessProvider`: Guest -> login; Free M20-M22 -> coming soon;
  Free M23-M29 -> payments; Plus/FamilyPlus -> coming soon.
- Fail closed cho access null/error/malformed/unknown va module ID la; membership
  plan thieu trong effective-access map khong con fallback thanh Free.
- Them segment-boundary protected prefix; V1 Features Hub chi import core/shared,
  khong import V2 membership.
- Placeholder khong co form, persistence, module health API/AI, quota commit,
  notification, device permission hoac production sample health data.
- Tao feature note va focused tests cho catalog, responsive UI, route, resolver
  va access page.

## File code/docs chinh da sua

- `docs/BD/advanced_health/BD_BioAI_Advanced_Health_Features_v1.0.md` - BD
  chi tiet M20-M29.
- `docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md` - extension
  registry, baseline M01-M19 khong doi.
- `docs/DD/README.md` va `docs/checklist/checklist_*DD.md` - DD backlog va
  coding gate 0%.
- `.codex/PROJECT_MAP.md` - route context toi Advanced Health BD.
- `docs/features/advanced-health-catalog/001-feature-advanced-health-catalog.md`
  - feature note cua UI shell.
- `lib/shared/health_features/health_feature_catalog.dart` - catalog chung.
- `lib/core/constants/routes/health_module_route_paths.dart` - route contract.
- `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart`
  - 19 cong cu va hai khu vuc responsive.
- `lib/app_versions/v2/features/health_modules/` - resolver/access/support page.
- `lib/app_versions/v2/features/membership_entitlement/domain/entities/effective_access.dart`
  - fail closed khi membership plan thieu.
- `lib/app_versions/v2/router/v2_router.dart` - route dong va protected prefix.
- `test/shared/health_features/`, `test/features/features_hub/`,
  `test/app_versions/v2/features/health_modules/` va
  `test/app_versions/v2/router/` - focused tests.

## Commands va bang chung

- `dart format --output=none --set-exit-if-changed <13 touched Dart files/dirs>`:
  PASS - 13 files, 0 changed.
- `flutter analyze <10 touched source/test paths>`: PASS - no issues.
- `flutter test test/shared/health_features/health_feature_catalog_test.dart test/features/features_hub/features_hub_page_test.dart test/app_versions/v2/features/health_modules/domain/health_module_access_resolver_test.dart test/app_versions/v2/features/health_modules/presentation/health_module_access_page_test.dart test/app_versions/v2/router/v2_health_module_route_test.dart`:
  PASS - 22 tests.
- `flutter test test/architecture_version_boundary_test.dart`: FAIL o hai vi
  pham da ton tai ngoai diff: V1 `dashboard_page.dart` import V2 cloud sync va
  V2 `auth_pages.dart` import `sale_referral`; file M20-M29 moi khong xuat hien
  trong violation list.
- Targeted boundary `rg`: PASS - Features Hub moi khong import V2/V3/Sale;
  health-module feature moi khong import V3/Admin/Sale/SQLite/local tier.
- BD traceability check: PASS - 10 module section, UC-25..UC-34, bay source bat
  buoc va khong co DD folder M20-M29.
- Placeholder side-effect scan: PASS - khong co SQLite/Supabase health write,
  AI client hoac `subscription_tier` trong slice moi.
- Schema scope check: PASS - khong co SQL/migration/Supabase schema change.
- `powershell -ExecutionPolicy Bypass -File .codex/tool/codex_quick_check.ps1`:
  PARTIAL/FAIL - `flutter pub get` PASS, sau do repo-wide Dart format gate phat
  hien 56 file baseline chua theo formatter hien tai va dung. Formatter side
  effect tren 56 file ngoai scope da duoc khoi phuc; khong giu diff ngoai task.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`:
  PASS truoc history refresh.
- `git diff --check`: PASS; chi co line-ending warning cua working tree.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`:
  PASS - refresh history/task-skills tu 81 worklogs.
- Final Codex integrity va `git diff --check`: PASS; diff check chi co
  line-ending warning cua working tree.

## Loi/Rui ro

- BD M20-M29 van Draft; UI shell khong phai nghiep vu da phat hanh va khong
  duoc tinh la DD/coding progress.
- Clinical/privacy/retention/schema/RLS va AI evaluation blockers trong BD phai
  duoc chot truoc moi DD va business implementation.
- Architecture boundary test toan repo con FAIL do hai dependency baseline ngoai
  pham vi; targeted scan xac nhan thay doi nay khong them violation moi.
- Quick check toan repo con FAIL o baseline formatter drift; targeted format,
  analyze va tests cua scope nay deu PASS.

## Ty le hoan thanh

- Hoan thanh: BD chi tiet, docs traceability, catalog 10 module, UI 19 cong cu,
  trusted access gate, shared coming-soon flow va focused tests.
- Giu 0% theo chu dinh: DD completeness va business coding M20-M29.
- Khong thay doi: health data storage, SQLite/Supabase, schema/RLS, AI/API,
  notification, device/wearable/OCR va nghiep vu y khoa.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - UI shell, access gate va BD dung chung mot registry,
  co fail-closed va ranh gioi an toan ro.
- Muc do hoan thanh task: hoan tat toan bo scope duoc phe duyet; nghiep vu that
  duoc giu 0% dung gate.
- Bang chung kiem chung: 22 focused tests, targeted analyzer/format, BD contract,
  side-effect/schema scans va Codex integrity PASS; hai global gate co baseline
  blocker duoc ghi ro.
- Diem ton token/chua toi uu: quick-check script co formatter mutating nen tao
  side effect ngoai scope truoc khi fail; da khoi phuc chinh xac.
- Cach toi uu cho phien sau: doc script broad check truoc khi chay, uu tien
  non-mutating targeted format va tach baseline gate khoi acceptance cua diff.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
