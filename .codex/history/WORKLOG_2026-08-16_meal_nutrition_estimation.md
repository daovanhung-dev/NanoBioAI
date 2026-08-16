# WORKLOG 2026-08-16 — Meal nutrition estimation v18

## Scope

- Add ingredient-based estimated nutrition per serving for source meal recipes that still have `nutrition_status=missing_source_data`.
- Add sugar, saturated fat, sodium, cholesterol, potassium, calcium and iron through Supabase, SQLite, catalog/meal-plan snapshots, cloud sync and meal UI.
- Keep unknown micronutrients nullable; never coerce unknown values to zero.
- Preserve recipe provenance separately from estimated nutrition and label estimates explicitly in UI.

## Implementation

- Bumped SQLite schema to v18 and added idempotent `MigrationV18` for catalog/meal-plan nutrition fields.
- Added deterministic offline `MealNutritionEstimator` using representative generic per-100g USDA FoodData Central values. Unquantified seasonings are ignored; insufficient ingredient coverage stays `missing_source_data`.
- Enriched bundled/Supabase catalog rows at load time so rollout does not depend on regenerated artifacts being deployed first.
- Added micronutrients and `nutrition_status` to meal-plan snapshots, AI normalization, replacement flow and cloud snapshot filtering.
- Added Supabase v18 migration and validator. The migration extends `insert_mobile_snapshot_row` so the latest monolithic `sync_my_mobile_snapshot` whitelist can accept the new meal-plan fields without redefining that large RPC.
- Added `tools/enrich_meal_catalog_nutrition.py` to enrich `assets/data/meal_catalog_v1.json` and regenerate the `meal_catalog` block in `docs/supabase/seed_data.sql` while preserving earlier fixture sections.
- Reworked the meal card/detail presentation: compact kcal + macro summary on cards; per-serving macro/micronutrient sections and estimate disclosure in detail.

## Validation performed

- `python -m py_compile tools/enrich_meal_catalog_nutrition.py test/tools/test_enrich_meal_catalog_nutrition.py` — PASS.
- `python test/tools/test_enrich_meal_catalog_nutrition.py -v` — PASS, 3/3 tests.
- Synthetic end-to-end generator run — PASS: enriched JSON, preserved seed prefix, regenerated v18 SQL columns/status and final commit.
- Static delimiter scan across all changed Dart files — PASS, no unmatched `()[]{}` found after conservative string/comment stripping.
- Static field-propagation scan — PASS for all seven micronutrients across local schema, Supabase migration and cloud-sync extension.
- Checked current `docs/supabase/setup.sql`: `meal_catalog.nutrition_status` has no restrictive CHECK constraint in the current main schema, so `estimated_from_ingredients` does not require constraint replacement.

## Not executed / blockers

- Flutter/Dart executables are not available in this runner, so `dart format`, `flutter analyze` and Flutter/Dart tests were not executed here. The Dart tests added in this change must be run in the project Flutter environment before merge/release.
- No Supabase sandbox/staging connection is available here; `docs/supabase/20260816_meal_nutrition_v18.sql` remains a migration to review and execute in sandbox/staging before production.
- The runner cannot clone/download the full GitHub checkout, so the real 163-recipe `assets/data/meal_catalog_v1.json` and generated `docs/supabase/seed_data.sql` were not rewritten in this session. Runtime enrichment is active immediately, and the deterministic tool is included for regeneration in a full checkout.
- The monolithic `docs/supabase/setup.sql` could not be materialized locally from the connector without a full checkout. The deployable v18 migration is included separately; fold it into the canonical setup file when running the normal repository SQL consolidation workflow.
- `.codex/history/WORKLOG_INDEX.md` was not regenerated because the repository history-refresh script cannot run without the full checkout.
