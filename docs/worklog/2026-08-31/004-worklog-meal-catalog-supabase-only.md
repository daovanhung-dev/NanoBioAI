Commit de xuat: fix(meal): ghi nhan Supabase-only meal catalog

# Worklog - Supabase-only meal catalog

## Thoi gian

- Ngay: 2026-08-31
- Bat dau: phien hien tai
- Ket thuc: 2026-08-31 15:15 +07
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: bugfix
- Module chinh: AI / Meal Plan / SQLite catalog / Supabase cache
- Yeu cau goc: AI chi tao mon co trong Supabase; fallback cung chi dung du lieu da dong bo tu Supabase.

## Da lam

- Xac dinh nguyen nhan: 163 mon Supabase deu `is_plan_eligible = false`, trong khi selector loai cac mon nay.
- Xac minh linked Supabase co 163 active non-fixture meals, deu `unclassified`.
- Bo meal seed runtime tu `AiCatalogSeeder`, khong con nap mon tu asset bundled.
- Them SQLite migration v24 de xoa cac meal row legacy tren thiet bi cu.
- Doi cache refresh sang atomic `replaceMeals` de local table chi la mirror Supabase.
- Cho phep source recipe Supabase qua selector va cho phep cache Supabase lam fallback.
- Khi khong co refresh/cache hop le, luong tao lich dung voi thong bao an toan.
- Cap nhat contract tests va tai lieu version SQLite len v24.

## File code/docs da sua

- `lib/services/supabase/meal_catalog/meal_catalog_cache_refresh_service.dart` - mirror remote catalog va kiem tra cache khong phu thuoc `is_plan_eligible`.
- `lib/app_versions/v1/features/meal_plan/domain/services/meal_candidate_selector.dart` - cho phep source recipe active non-fixture.
- `lib/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart` - fallback cache Supabase khi refresh that bai.
- `lib/core/storage/localdb/seeders/ai_catalog_seeder.dart` - bo seed meal runtime.
- `lib/core/storage/localdb/migrations/migration_v24.dart` - xoa meal legacy.
- `lib/core/storage/localdb/database_service.dart`, `lib/core/storage/localdb/database_version.dart` - wire migration va bump version.
- `test/**` liên quan meal catalog, selector, migration va source-truth contracts - cap nhat regression expectations.
- `.codex/AGENTS.md`, `.codex/README.md`, `.codex/domains/sqlite.md`, `docs/README.md` - cap nhat SQLite v24.
- `docs/fixbug/meal-catalog-supabase-only/001-fixbug-meal-catalog-supabase-only.md` - ghi nhan nguyen nhan va cach xu ly.

## Tai lieu lien quan

- `docs/supabase/README.md`
- `docs/supabase/01_build_system.sql`
- `docs/supabase/02_seed_data.sql`
- `lib/app_versions/v1/services/ai/prompts/meal_plan_prompt.dart`
- `supabase/functions/nabi-ai-generate/handler.ts`

## Commands

- `supabase db query --linked ...`: PASS - 163 active non-fixture rows; 163 source rows khong plan eligible.
- `deno test supabase/functions/nabi-ai-generate/handler_test.ts`: PASS - 10 tests.
- `git diff --check`: PASS.
- `dart format ...`: UNVERIFIED - khong co lenh `dart`.
- `flutter analyze ...`: UNVERIFIED - khong co lenh `flutter`.
- `flutter test ...`: UNVERIFIED - khong co lenh `flutter`.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL - manifest source-truth thieu va path stale da ton tai truoc phien.
- Edge Function deploy: SKIPPED - khong sua Edge Function; function khong doc/chon meal catalog.

## Loi/Rui ro

- Da fix: selector khong con loai 163 source recipes vi `is_plan_eligible = false`; cache khong con giu meal seed app.
- Chua fix: Flutter/Dart checks chua chay duoc do thieu SDK trong moi truong.
- Can kiem tra tiep: chay targeted Flutter tests/analyze va test onboarding/generated-plan tren Android khi co SDK; xac nhan migration v24 tren thiet bi nang cap.

## Ty le hoan thanh

- Hoan thanh: runtime patch, migration, contract tests, linked Supabase count verification, Edge handler regression test.
- Dang do: Flutter format/analyze/test va device acceptance.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - da truy nguyen den selector/cache va xac minh truc tiep so lieu Supabase thay vi dua vao docs.
- Muc do hoan thanh task: hoan thanh phan code va backend data contract; con thieu Flutter runtime verification do moi truong.
- Bang chung kiem chung: linked Supabase count 163, Deno handler tests 10/10, diff whitespace PASS; Flutter checks UNVERIFIED.
- Diem ton token/chua toi uu: mot so docs audit lich su va output catalog lon khong can doc het; da chuyen sang grep/find targeted.
- Cach toi uu cho phien sau: cai san Flutter/Dart hoac chay targeted test tren CI/device truoc khi claim runtime PASS.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
