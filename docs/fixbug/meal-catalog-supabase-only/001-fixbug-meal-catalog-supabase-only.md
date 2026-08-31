Commit de xuat: fix(meal): chi tao thuc don tu catalog Supabase

# Fixbug - Meal catalog Supabase-only

## Pham vi loi

- AI tao thuc don khong su dung duoc 163 mon dang co trong Supabase.
- Cache local truoc day gop catalog Supabase voi mon seed trong app.
- Fallback co the chon mon khong co trong Supabase.

## Nguyen nhan

- 163 dong Supabase deu co `is_plan_eligible = false` va `meal_type = unclassified`.
- `MealCandidateSelector` loai moi dong `is_plan_eligible = false`, lam catalog truyen cho AI rong.
- `MealCatalogCacheRefreshService` dung `upsertMeals`, giu lai 40 mon app seed.

## Xu ly

- Meal catalog SQLite tro thanh mirror cua cac dong active, non-fixture tu Supabase.
- Bo seed mon an tu `AiCatalogSeeder`; chi giu seed bai tap va tac vu lich trinh.
- Them migration v24 de xoa cac dong meal legacy da duoc bundled tren thiet bi cu.
- Mo selector cho source recipes Supabase, bao gom dong `unclassified` va khong plan eligible.
- Khi Supabase loi, chi dung cache da dong bo tu Supabase; neu khong co cache thi dung tao lich.
- Giu prompt/validator chi cho phep `meal_code` trong catalog da nap.

## Bang chung du lieu

- Read-only query tren linked Supabase project: 163 active non-fixture meals.
- Ca 163 dong co `is_plan_eligible = false`.
- Ca 163 dong co `meal_type = unclassified`.
- Script seed canonical van kiem tra recipe count bang 163.

## Kiem chung

- `deno test supabase/functions/nabi-ai-generate/handler_test.ts`: PASS, 10 tests.
- `supabase db query --linked ...`: PASS, catalog count 163.
- `git diff --check`: PASS.
- Flutter/Dart format, analyze va test: UNVERIFIED, moi truong khong co lenh `dart`/`flutter`.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL do loi ton tai truoc ve manifest thieu va cac path lich su stale, khong do thay doi meal catalog.

## Pham vi Edge Function

- Khong sua hoac deploy `nabi-ai-generate`; function chi chuyen prompt den provider va khong chon mon.

