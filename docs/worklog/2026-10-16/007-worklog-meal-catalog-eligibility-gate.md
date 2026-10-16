Commit de xuat: feat(m02): khoa catalog candidate den khi du dieu kien

# Worklog - M02 meal catalog eligibility gate

## Thoi gian

- Ngay: 2026-10-16
- Bat dau: tiep tuc tu ngu canh trien khai truoc do; gio bat dau khong duoc ghi lai
- Ket thuc: 11:06
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: coding, targeted verification, worklog/context
- Module chinh: M02 PERSONAL_SCHEDULE_AI, meal catalog
- Yeu cau goc: Doc `assets/data/nabi_3000_mon_viet_moi.json` va dua cac mon vao luong AI tao lich ca nhan theo plan duoc duyet.
- Dieu kien scope: rights va review du lieu chua duoc xac nhan; candidate phai tiep tuc bi khoa, khong tao catalog runtime v36.

## Da lam

- Kiem tra candidate co 3.000 ma duy nhat, khong trung 163 ma cu; tat ca `is_active=true` nhung `is_plan_eligible=false`, `meal_type=unclassified`, nutrition chua xac minh, metadata rang buoc cho review. Khong sua JSON goc.
- Loai JSON candidate khoi Flutter assets; them asset gate test de dam bao catalog cu van duoc dong goi va candidate khong vao bundle.
- Them eligibility gate dung chung cho prompt, normalizer, selector va fallback. Chi giu tuong thich `source_imported` trong namespace ma cu `src_`; mon moi can `source_verified` va day du evidence dinh duong, rang buoc, di ung, cong thuc va provenance.
- Prompt chi gui ma/ten va nutrition summary trong byte budget; ma/ten khong bi rut gon. Sau khi AI tra ma, chi tiet van duoc hydrate tu SQLite.
- Tang staging prompt version len `personal_schedule_v10_catalog_eligibility_gate`.
- Cap nhat intake contract, review record, feature doc va checklist de tach workspace JSON 3.000 mon khoi archive Downloads khac va ghi ro chua co rights/provenance theo mon.
- Khong tao catalog 3.163 dong, migration v36, seeder moi hay prompt chua duyet. Validator package synthetic truoc do trong cung phien PASS voi 3.163 ma, 3.000 mon moi va evidence gia lap; ket qua nay chi kiem tra contract, khong xac nhan quyen su dung hoac do chinh xac du lieu that.

## File code/docs da sua

- `pubspec.yaml` - khai bao asset cu bang duong dan cu the, khong dong goi JSON candidate.
- `lib/core/storage/localdb/models/ai_catalog_models.dart` - shared eligibility gate va whitelist legacy `src_`.
- `lib/app_versions/v1/features/meal_plan/domain/services/meal_candidate_selector.dart` - loc candidate theo eligibility chung.
- `lib/app_versions/v1/features/meal_plan/data/models/meal_plan_ai_normalizer.dart` - tu choi ma khong duyet/khong du dieu kien.
- `lib/app_versions/v1/services/ai/ai_service.dart` - eligibility cho prompt preparation va fallback.
- `lib/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart` - gui selectable code/name, giu danh sach ma ten trong budget.
- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - doi staging prompt version.
- `test/app_versions/v1/features/meal_plan/presentation/utils/meal_catalog_candidate_asset_gate_test.dart`, cac test selector/normalizer/prompt/AIService - bao phu gate va duong di chinh.
- `tools/validate_meal_catalog_bundle.py`, `docs/meal_catalog/*`, `docs/features/ai-generated-plan/005-feature-full-catalog-ai-context.md`, `docs/checklist/*` - intake, rights/dinh duong gate va trang thai xac minh.

## Tai lieu lien quan

- `docs/meal_catalog/3000_recipe_dataset_intake.md`
- `docs/meal_catalog/3000_recipe_dataset_review_2026-10-16.md`
- `docs/meal_catalog/open_recipe_source_research_2026-10-16.md`
- `docs/features/ai-generated-plan/005-feature-full-catalog-ai-context.md`

## Commands

- `flutter test test/app_versions/v1/features/meal_plan/meal_candidate_selector_test.dart test/app_versions/v1/features/meal_plan/meal_plan_unclassified_catalog_test.dart test/features/meal_plan/data/meal_plan_ai_normalizer_test.dart test/app_versions/v1/services/ai/prompts/meal_plan_prompt_test.dart test/app_versions/v1/features/meal_plan/presentation/utils/meal_catalog_candidate_asset_gate_test.dart`: PASS 21 tests.
- `flutter test test/services/ai/ai_service_test.dart --name 'meal prompt includes only selectable SQLite code and name rows|meal prompt includes every selectable provided row exactly once|meal prompt excludes the active unreviewed 3000-meal candidate|production meal prompt includes all 163 SQLite code/name pairs|AI service sends request content above 32,000 characters|slot AI output outside the eligible subset fails closed|active unreviewed candidate is rejected and excluded from fallback'`: PASS 7 tests.
- `flutter test test/services/ai/ai_service_test.dart --reporter expanded`: FAIL, 14 assertions ve logging/exception trong cac ca chat, thieu API key va model failures; khong phai focused eligibility assertions.
- Dart MCP `analyze_files` tren source/test M02: PASS, khong co loi.
- `python3 -m py_compile tools/validate_meal_catalog_bundle.py`: PASS.
- Validator voi package synthetic 3.163 mon va rights/evidence fixture synthetic: PASS; khong phai candidate da duoc phe duyet.
- Kiem tra asset/candidate: 3.000 candidate ma duy nhat, 0 plan-eligible, 3.000 active/unclassified; 163 ma cu duy nhat va deu nam trong namespace `src_`.
- `git diff --check`: PASS.
- `flutter build apk --release --no-pub`: FAIL tai Java compile vi generated `GeneratedPluginRegistrant.java` tham chieu `dev.flutter.plugins.integration_test.IntegrationTestPlugin` khong co trong classpath.
- Flutter release asset output hien co: 73 MB; khong tao duoc APK moi nen chua co kich thuoc APK hien tai.
- `flutter run -d linux --no-pub`: khong the khoi dong vi thieu CMake; DTD khong tim thay app dang ket noi de hot reload.

## Loi/Rui ro

- Da fix: candidate khong the vao prompt/normalizer/fallback chi vi co `is_active=true`; `source_imported` chi giu tuong thich cho namespace legacy `src_`.
- Chua fix: 14 test trong toan bo `ai_service_test.dart` that bai o ky vong logging/exception cua cac ca chat va model failure; can tach/trace rieng neu muon lam sach toan bo suite.
- Can kiem tra tiep: nhan rights/provenance recipe va dinh duong cho ca 3.000 ma; review loai bua, cong thuc, di ung/chong chi dinh; sau do moi tao package 3.163, migration/seeder, kiem tra v35->v36 va hydrate.
- Can kiem tra tiep: giai quyet generated plugin registrant/build environment, sau do do APK va QA device fresh.

## Ty le hoan thanh

- Hoan thanh: eligibility gate, prompt/normalizer/fallback hardening, asset exclusion, intake validator va targeted verification.
- Dang do: tich hop runtime 3.000 mon; dieu kien rights va review chua dat, nen theo plan phien nay chua tao migration v36.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - catalog cu duoc giu tuong thich co gioi han; candidate moi fail-closed tren cac duong chon.
- Muc do hoan thanh task: hoan thanh phan co the lam truoc rights gate; muc tieu dua 3.000 mon vao runtime chua hoan tat.
- Bang chung kiem chung: 28 focused Flutter tests PASS; targeted analyzer khong loi; validator contract PASS tren fixture synthetic; full AIService suite va release APK con loi duoc ghi rieng.
- Diem ton token/chua toi uu: da chay full AIService suite sau khi focused assertions xanh de phat hien regression; build release khong tao APK.
- Cach toi uu cho phien sau: bat dau bang rights/data bundle theo intake contract; dung validator truoc migration va chay test upgrade/prompt/hydration tren SQLite synthetic.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
